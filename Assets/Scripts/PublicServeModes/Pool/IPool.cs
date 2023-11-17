using System;

namespace Tools.Pool
{
    public interface IPool<E>
    {
        int Count { get; }
        E AddOneObject();
        void AddMoreObjects(int check_index);
        E GetOneObject();
        void RecycelOneObject(E e);
        void RecycleAllObjects();
        void ClearPool();
        void ForeachPool(Action<E> act);
    }

    public interface IPooling<EKey, EValue>
    {
        EValue GetOneObject(EKey type);
        void RecycelOneObject(EKey key, EValue e);
        void RecycleAllObject();
        void RecycleAllObject(EKey type);
        void ClearPool();
    }
}
