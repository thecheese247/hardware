library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library std;
    use std.textio.all;


-- Declare the I/O ports of the testbench.
entity tb_dlock is
  port
  (
    data  : out std_logic;
    clock : out std_logic;
    reset : out std_logic;
    lock  : out std_logic;
    alarm : out std_logic
  );
end entity;


-- Define the testbench body.
architecture TB of tb_dlock is

  -- Declare what a 'dlock' module looks like.
  component dlock
    port
    (
      data  : in  std_logic;
      clock : in  std_logic;
      reset : in  std_logic;
      lock  : out std_logic;
      alarm : out std_logic
    );
  end component;

  -- Some internal wired in the testbench.
  signal dl_data : std_logic;
  signal dl_clock : std_logic;
  signal dl_reset : std_logic;
  signal dl_lock : std_logic;
  signal dl_alarm : std_logic;

begin

  -- The instance of the dlock module.
  dl: dlock
    port map (
      data  => dl_data,
      clock => dl_clock,
      reset => dl_reset,
      lock  => dl_lock,
      alarm => dl_alarm
    );

  -- Wire up the outputs so the dlock signals are forwarded to a
  -- waveform viewer inspecting the testbench.
  data  <= dl_data;
  clock <= dl_clock;
  reset <= dl_reset;
  lock  <= dl_lock;
  alarm <= dl_alarm;


  -- Signal generator (clock, input) and debug output in one flush.
  -- Simulated VHDL does have its strengths...
  process
    variable output_line : line;
    variable c : std_logic_vector(4 downto 0);
  begin
    write(output_line, String'(" tb_dlock: Simulation started."));
    writeline(output, output_line);

    -- Initial reset.
    dl_data <= '0';
    dl_reset <= '1';
    dl_clock <= '0';
    wait for 5 ns;
    dl_clock <= '1';
    wait for 5 ns;
    dl_reset <= '0';

    -- dlock takes input code MSB first.
    for code in 0 to 31
    loop
      c := std_logic_vector(to_unsigned(code, 5));

      -- Prepare output to stdout
      write(output_line, String'(" tb_dlock: Code "));
      write(output_line, code);
      write(output_line, String'(": "));

      -- Feed the new code bit by bit.
      for bit in 4 downto 0
      loop
        dl_data <= c(bit);

        dl_clock <= '0';
        wait for 5 ns;
        dl_clock <= '1';
        wait for 5 ns;

        if dl_data = '1' then
          write(output_line, String'("  1 "));
        else
          write(output_line, String'("  0 "));
        end if;

        if dl_lock = '1' then
          write(output_line, String'("L"));
        elsif dl_lock = '0' then
          write(output_line, String'("l"));
        else
          -- Should never happen, as dl_lock should be 0 or 1.
          -- Only if the output pin is not connected...
          write(output_line, String'("l?"));
        end if;

        if dl_alarm = '1' then
          write(output_line, String'("A"));
        elsif dl_alarm = '0' then
          write(output_line, String'("a"));
        else
          -- Should never happen, as dl_alarm should be 0 or 1.
          -- Only if the output pin is not connected...
          write(output_line, String'("a?"));
        end if;
      end loop;



      writeline(output, output_line);


      -- Reset the dlock for the next code to be checked.
      dl_data <= '0';
      dl_reset <= '1';
      dl_clock <= '0';
      wait for 5 ns;
      dl_clock <= '1';
      wait for 5 ns;
      dl_reset <= '0';
    end loop;


    -- Final 7 clock cycles of do-nothing, like in the original waveform.
    dl_data <= '0';
    dl_reset <= '0';
    for c in 7 downto 1
    loop
      dl_clock <= '0';
      wait for 5 ns;
      dl_clock <= '1';
      wait for 5 ns;
    end loop;

    -- Alright, we're done.
    write(output_line, String'(" tb_dlock: Simulation finished."));
    writeline(output, output_line);

    -- Wait forever, thus ending the simulation.
    wait;
  end process;
end architecture;
