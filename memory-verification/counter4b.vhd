LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY counter4b IS
	PORT(
		clock	: 	IN STD_LOGIC;
		--bit0, bit1, bit2, bit3	: OUT BIT
		reset	:	IN BIT;
		bits	:	OUT STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010"
		);
END counter4b;

ARCHITECTURE counter OF counter4b IS
	BEGIN
		PROCESS(reset, clock)
			VARIABLE number : NATURAL := 0;
			BEGIN
				IF reset = '1' THEN
					number := 0;
				ELSIF clock'event and clock = '1' THEN
					number := (number + 1) MOD 10;
					-- TESTE DE MESA
					-- 9 = 1001
					-- 9 MOD 2 = 1 (BIT)
					-- 4 MOD 2 = 0 (BIT)
					-- 2 MOD 2 - 0 (BIT)
					-- 1 MOD 2 = 1 (BIT)
					
					-- 12 = 1100
					-- 12 MOD 2 = 0
					-- 6  MOD 2 = 0
					-- 3  MOD 2 = 1
					-- 1  MOD 2 = 1
					
					-- IMPLEMENTAÇÃO MAIS PORCA
					--bit0 <= bit'val(number MOD 2);
					--bit1 <= bit'val((number / 2) MOD 2);
					--bit2 <= bit'val((number / 4) MOD 2);
					--bit3 <= bit'val((number / 8) MOD 2);			
					--number := (number + 1) MOD 10;
				END IF;
				bits <= conv_std_logic_vector(number, 4);
		END PROCESS;
END counter;