import std.concurrency;
import std.stdio;

import vibe.d;

shared size_t numElems;
shared size_t modulus;
shared string[] q;
shared size_t pIdx, cIdx, qSize;
shared Lock l;

shared static this()
{
    import vibe.core.args;
    l = new Lock();

    int pow = 12;
    getOption("size", &pow, "The size of the queue. (E.g. 2^n where n = 0-32 or 64)");
    if (!finalizeCommandLineOptions()) return;
    pow = (pow == 0 || pow == size_t.sizeof) ? size_t.sizeof - 1 : pow;
    numElems = 2 ^^ pow;
    modulus = (2 ^^ pow) - 1;
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
                cIdx = (cIdx + 1) & modulus;
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
                pIdx = (pIdx + 1) & modulus;
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
