import std.concurrency;
import std.stdio;

import vibe.d;

shared size_t numElems = 2;
shared string[] q;
shared size_t pIdx, cIdx, qSize;
shared Lock l;

shared static this()
{
    import vibe.core.args;
    l = new Lock();

    getOption("size", &numElems, "The size of the queue.");
    if (!finalizeCommandLineOptions()) return;
    q.length = numElems;
    writeln("Size of the queue: ", numElems);

    auto router = new URLRouter;
    router.registerRestInterface(new QueueInterface());

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

class Lock { }

interface QueueAPI
{
    @path("get")
    @method(HTTPMethod.GET)
    string get();

    @path("push")
    @method(HTTPMethod.POST)
    void push(string msg);

    @path("stats")
    @method(HTTPMethod.GET)
    Stats stats();
}

class QueueInterface : QueueAPI
{
    string get()
    {
        synchronized(l)
        {
            if (qSize > 0)
            {
                cIdx = (cIdx + 1) % numElems;
                qSize = qSize - 1;
                return q[cIdx];
            }
            else
            {
                throw new HTTPStatusException(204, "No messages to return.");
            }
        }
    }

    void push(string msg)
    {
        synchronized(l)
        {
            if (qSize < numElems)
            {
                pIdx = (pIdx + 1) % numElems;
                q[pIdx] = msg;
                qSize = qSize + 1;
            }
            else
            {
                throw new HTTPStatusException(429, "Cannot accept any new messages.");
            }
        }
    }

    Stats stats()
    {
        return Stats(qSize);
    }
}

struct Stats
{
    size_t queueSize;
}