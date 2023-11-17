using UnityEngine;

public abstract class SingletonBehaviour<T> : MonoBehaviour where T : SingletonBehaviour<T>
{
    public static T instance { get; private set; }
    public virtual void Init()
    {
        if (instance != null) return;
        instance = this as T;
        MoreInit();
    }

    protected abstract void MoreInit();
}