defmodule RoboticaFaceWeb.ApiController do
  use RoboticaFaceWeb, :controller

  alias RoboticaFaceWeb.Token

  defp delta_to_string(scheduled, now) do
    {:ok, seconds, _microseconds, _} = Calendar.DateTime.diff(scheduled, now)

    hours = div(seconds, 3600)
    seconds = rem(seconds, 3600)

    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)

    cond do
      hours > 1 -> "#{hours} hours, #{minutes} minutes"
      hours == 1 -> "1 hour, #{minutes} minutes"
      minutes > 1 -> "#{minutes} minutes"
      minutes == 1 -> "1 minute"
      seconds == 1 -> "1 second"
      true -> "#{seconds} seconds"
    end
  end

  defp parse_steps(steps) do
    steps
    |> Enum.map(fn step ->
      time = Timex.parse!(step["required_time"], "{ISO:Extended}")
      %{step | "required_time" => time}
    end)
  end

  defp count_tasks(steps) do
    Enum.reduce(steps, 0, fn step, acc -> acc + length(step["tasks"]) end)
  end

  defp filter_steps(steps, filter_task?) do
    steps
    |> Enum.map(fn step ->
      tasks = Enum.filter(step["tasks"], filter_task?)
      %{step | "tasks" => tasks}
    end)
    |> Enum.filter(fn step ->
      length(step["tasks"]) > 0
    end)
  end

  defp filter_steps_before_time(steps, threshold) do
    steps
    |> Enum.filter(fn step ->
      Calendar.DateTime.before?(step["required_time"], threshold)
    end)
  end

  defp filter_todo_task?(task) do
    case task["mark"] do
      "done" -> false
      "cancelled" -> false
      _ -> true
    end
  end

  defp filter_query_task?(task, query) do
    msg = get_in(task, ["action", "message", "text"])

    query = String.downcase(query)

    msg =
      case msg do
        nil -> nil
        msg -> String.downcase(msg)
      end

    Enum.all?(String.split(query), fn word ->
      case msg do
        nil ->
          false

        msg ->
          regexp = ~r"\b#{Regex.escape(word)}\b"
          not is_nil(Regex.run(regexp, msg))
      end
    end)
  end

  defp steps_to_message(steps, now) do
    messages =
      steps
      |> Enum.map(fn step ->
        time = step["required_time"]

        msgs =
          Enum.map(step["tasks"], fn task ->
            RoboticaPlugins.ScheduledTask.task_to_msg(task)
          end)
          |> Enum.filter(fn msg -> not is_nil(msg) end)

        {time, msgs}
      end)
      |> Enum.filter(fn {_, msgs} -> length(msgs) > 0 end)

    case messages do
      [] ->
        nil

      list ->
        Enum.map(list, fn {time, msgs} ->
          time_str = delta_to_string(time, now)
          msg_str = Enum.join(msgs, " and ")
          "In #{time_str}, #{msg_str}"
        end)
        |> Enum.join(" ")
    end
  end

  def each_task(steps, process) do
    Enum.each(steps, fn step ->
      Enum.each(step["tasks"], fn task ->
        process.(step["required_time"], task)
      end)
    end)
  end

  def reduce_task(steps, initial, process) do
    Enum.reduce(steps, initial, fn step, acc ->
      Enum.reduce(step["tasks"], acc, fn task, task_acc ->
        process.(step["required_time"], task, task_acc)
      end)
    end)
  end

  def get_context(params, context_name) do
    session = Map.get(params, "session", "")
    contexts = get_in(params, ["queryResult", "outputContexts"])
    full_context_name = "#{session}/contexts/#{context_name}"

    results = Enum.filter(contexts, fn context -> context["name"] == full_context_name end)

    case results do
      [head | _] -> head
      [] -> nil
    end
  end

  def get_filtered_steps(params, now) do
    context = get_context(params, "task_filter")
    query = get_in(context, ["parameters", "query"])
    {:ok, steps} = RoboticaFace.Schedule.get_schedule()

    midnight =
      RoboticaFace.Date.tomorrow(now)
      |> RoboticaFace.Date.midnight_utc()

    steps
    |> parse_steps()
    |> filter_steps_before_time(midnight)
    |> filter_steps(fn task -> filter_query_task?(task, query) end)
  end

  def index(conn, params) do
    IO.inspect(params)

    token = get_in(params, ["originalDetectIntentRequest", "payload", "user", "idToken"])

    result =
      case token do
        nil -> {:error, "No token"}
        _ -> Token.verify_and_validate(token)
      end

    known_user =
      case result do
        {:ok, claims} ->
          case {claims["email"], claims["email_verified"]} do
            {"brian@linuxpenguins.xyz", true} -> true
            _ -> false
          end

        {:error, _} ->
          false
      end

    assigns =
      cond do
        not known_user ->
          %{
            fulfillmentText:
              "I am so sorry. I do not know you. Tux says never to talk to strange penguins. Go away."
          }

        true ->
          process_intent(params)
      end

    IO.inspect(assigns)
    render(conn, "index.json", assigns)
  end

  defp process_intent(params) do
    query = Map.get(params, "queryResult", %{})
    intent = get_in(query, ["intent", "name"])
    parameters = Map.get(query, "parameters", %{})

    case intent do
      "projects/robotica-3746c/agent/intents/c2b9befe-126f-4452-bc18-018f126f6beb" ->
        {:ok, steps} = RoboticaFace.Schedule.get_schedule()
        now = Calendar.DateTime.now_utc()

        messages =
          steps
          |> parse_steps()
          |> filter_steps(&filter_todo_task?/1)
          |> Enum.take(3)
          |> steps_to_message(now)

        %{
          fulfillmentText: messages || "There are no tasks"
        }

      "projects/robotica-3746c/agent/intents/8059af23-6a9f-46a4-ab7f-7ea713a86d79" ->
        now = Calendar.DateTime.now_utc()
        steps = get_filtered_steps(params, now)
        message = steps_to_message(steps, now)
        count = count_tasks(steps)

        %{
          fulfillmentText: "There were #{count} tasks. #{message}"
        }

      "projects/robotica-3746c/agent/intents/472a3b36-0901-4da9-9afa-09156f718f46" ->
        now = Calendar.DateTime.now_utc()
        steps = get_filtered_steps(params, now)
        total_count = count_tasks(steps)
        status = parameters["TaskStatus"]

        count =
          reduce_task(steps, 0, fn _time, task, acc ->
            result = RoboticaFace.Mark.mark_task(task, status)

            case result do
              :error -> acc
              :ok -> acc + 1
            end
          end)

        %{
          fulfillmentText:
            "There were #{count} out of #{total_count} tasks that were marked as #{status}."
        }

      _ ->
        %{
          fulfillmentText: "Something went wrong! I am very sorry."
        }
    end
  end
end
