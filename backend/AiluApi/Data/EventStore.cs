using AiluApi.Events;

namespace AiluApi.Data;

public class EventStore
{
    private readonly List<object> _events = new();

    public void Append(object @event)
    {
        _events.Add(@event);
    }

    public IEnumerable<object> GetEvents() => _events;
}