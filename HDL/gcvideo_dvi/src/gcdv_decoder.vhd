----------------------------------------------------------------------------------
-- GCVideo DVI HDL
-- Copyright (C) 2014-2017, Ingo Korb <ingo@akana.de>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
-- THE POSSIBILITY OF SUCH DAMAGE.
--
-- gcdv_decoder: Decoder for the GameCube digital video port signals
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.video_defs.all;

entity gcdv_decoder is
  port (
    -- Gamecube signals
    VClockI           : in  std_logic; -- 54 MHz clock, pin 2
    VData             : in  std_logic_vector(7 downto 0);
    CSel              : in  std_logic; -- "ClkSel" signal, pin 3

    -- output clock enables
    PixelClockEnable  : out boolean; -- CE relative to input clock for complete pixels
    PixelClockEnable2x: out boolean; -- same, but at twice the pixel rate

    -- video output
    Video             : out VideoY422
  );
end gcdv_decoder;

architecture Behavioral of gcdv_decoder is
  signal current_y    : unsigned(7 downto 0);
  signal current_cbcr : unsigned(7 downto 0);
  signal current_flags: std_logic_vector(7 downto 0);
  signal prev_csel  : std_logic;
  signal in_blanking_first: boolean:=false;
  signal in_blanking: boolean;
  signal input_30khz: boolean := false;
  signal modecounter: natural range 0 to 3 := 0;
  signal vdata_buf: std_logic_vector(7 downto 0);
  signal prev_vdata_buf: std_logic_vector(7 downto 0);
  signal prev2_vdata_buf: std_logic_vector(7 downto 0);
  signal csel_buf : std_logic;
begin

  process (VClockI)
  begin
    if rising_edge(VClockI) then
      -- buffer incoming data to relax timing
      vdata_buf <= VData;
      csel_buf  <= CSel;
     
	
      prev_csel <= csel_buf;

      --Buffer 2 previous Y/Chroma values
      prev_vdata_buf <= vdata_buf;
      prev2_vdata_buf <= prev_vdata_buf;

      if prev_csel /= csel_buf then
        -- csel_buf has changed, current value is Y

	      if prev_vdata_buf=x"00" and vdata_buf /= x"00" then
		--First Pixel out of Blanking
		in_blanking_first<=true;
	      else
		in_blanking_first<=false;
	      end if;

        current_y <= unsigned(vdata_buf);

        if vdata_buf = x"00" then
          -- in blanking, next color is flags
          in_blanking <= true;
        else
          in_blanking <= false;
        end if;

        -- detect if it's a 15kHz or 30kHz video mode
        modecounter <= 0;
        if modecounter < 2 then
          input_30khz <= true;
        else
          input_30khz <= false;
        end if;

      else
        -- current value is color or flags
        modecounter <= modecounter + 1;

        -- read color just once in 15kHz mode
        if (not input_30khz and modecounter = 1) or input_30khz then
          if in_blanking then
            current_flags <= vdata_buf;
          else
           
		if in_blanking_first then
			--Generate Fake Cb Value
			current_cbcr  <= x"80";
		else
			--Use Prev Color Value
			current_cbcr  <= unsigned(prev2_vdata_buf);
		end if;

          end if;
        end if;
      end if;
      -- generate output signals
      if prev_csel /= csel_buf then
        -- output pixel data when the next Y value is received
        PixelClockEnable    <= true;
        PixelClockEnable2x  <= true;
        Video.Blanking      <= in_blanking;
        Video.HSync         <= (current_flags(4) = '0');
        Video.VSync         <= (current_flags(5) = '0');
        Video.CSync         <= (current_flags(7) = '0');
        Video.IsProgressive <= (current_flags(0) = '1');
        Video.IsPAL         <= (current_flags(1) = '1');
        Video.IsEvenField   <= (current_flags(6) = '1');
        if in_blanking then
          Video.PixelY    <= x"00";
          -- color during blanking is ignored by the 422-444 interpolator
          --Video.PixelCbCr <= x"80";
        else
          if current_y < x"10" then -- never triggers in my tests, but let's be paranoid anyway
            Video.PixelY <= x"00";
          else
            Video.PixelY    <= current_y - x"10"; -- pre-subtract the offset
          end if;
            Video.PixelCbCr <= current_cbcr;
        end if;
        Video.CurrentIsCb <= (csel_buf = '0');

        Video.Is30kHz <= input_30kHz;

      else
        PixelClockEnable <= false;
        if input_30khz or modecounter = 1 then
          PixelClockEnable2x <= true;
        else
          PixelClockEnable2x <= false;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
