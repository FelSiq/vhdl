LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY seg IS
	PORT(reset: IN STD_LOGIC;
		  num: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		  hex: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
		  );
END seg;

ARCHITECTURE behavior of seg IS

BEGIN
		d7s: PROCESS(num, reset)
		BEGIN
			IF reset = '1' THEN
				hex <= "1000000";
			ELSE 
				-- 0
				IF(num = "0000") THEN
					hex <= "1000000";
				-- 1
				ELSIF(num = "0001") THEN
					hex <= "1111001";
				-- 2 
				ELSIF(num = "0010") THEN
					hex <= "0100100";
				-- 3
				ELSIF(num = "0011") THEN
					hex <= "0110000";
				-- 4
				ELSIF(num = "0100") THEN
					hex <= "0011001";
				-- 5
				ELSIF(num = "0101") THEN
					hex <= "0010010";					
				-- 6
				ELSIF(num = "0110") THEN
					hex <= "0000010";
				-- 7
				ELSIF(num = "0111") THEN
					hex <= "1111000";
				-- 8
				ELSIF(num = "1000") THEN
					hex <= "0000000";
				-- 9
				ELSIF(num = "1001") THEN
					hex <= "0010000";
				-- A
				ELSIF(num = "1010") THEN
					hex <= "0001000";
				-- B
				ELSIF(num = "1011") THEN
					hex <= "0000011";
				-- C
				ELSIF(num = "1100") THEN
					hex <= "1000110";
				-- D
				ELSIF(num = "1101") THEN
					hex <= "0100001";
				-- E
				ELSIF(num = "1110") THEN
					hex <= "0000110";
				-- F
				ELSIF(num = "1111") THEN
					hex <= "0001110";
				END IF;							
			END IF;
		END PROCESS d7s;
END behavior;		
	