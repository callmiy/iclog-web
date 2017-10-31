defmodule Iclog.Observable.Sleep.Helper do
  defp make_start_end_times() do
    starts = Timex.now
    ends = Timex.shift starts, hours: 7
    {starts, ends}
  end

  def format_time(time)  do
    Timex.format! time, "{ISO:Extended:Z}"
  end

  def valid_attrs do
    {starts, ends} = make_start_end_times()
    %{
      comment: "some comment",
      start: (format_time starts),
      end: (format_time ends)
    }
  end

  def update_attrs do
    {starts, ends} = make_start_end_times()
    %{
      comment: "some updated comment",
      start: (format_time starts),
      end: (format_time ends)
    }
  end
end