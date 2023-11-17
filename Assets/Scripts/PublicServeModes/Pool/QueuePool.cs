using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Tools.Pool
{
    //使用场景：能够按顺序使用且按顺序回收
    public class QueuePool<E> : IPool<E>
    {
        private Queue<E> _pool = new Queue<E>();
        private List<E> _all_object_list = new List<E>();

        public int Count { get { return _pool.Count; } }
        private Action<E> SetUsed; //设置为 被占用 的方法
        private Action<E> SetUnused; //设置为 可用 的方法
        private Func<E> Generator; //创建对象方法
        public QueuePool(Action<E> SetUsed, Action<E> SetUnused, Func<E> Generator)
        {
            this.SetUsed = SetUsed;
            this.SetUnused = SetUnused;
            this.Generator = Generator ?? throw new Exception("Pool不允许生成方法为空");
        }

        public E AddOneObject()
        {
            E one = Generator();
            _pool.Enqueue(one);
            _all_object_list.Add(one);
            return one;
        }
        public void AddMoreObjects(int check_index)
        {
            if (check_index > _pool.Count)
            {
                E one = default(E);
                for (int i = 0; i < check_index - _pool.Count; i++)
                {
                    one = Generator();
                    _pool.Enqueue(one);
                    _all_object_list.Add(one);
                }
            }
        }

        public E GetOneObject()
        {
            E one;
            if (CanUse())
            {
                one = _pool.Dequeue();
            }
            else
            {
                one = Generator();
                _all_object_list.Add(one);
            }
            SetUsed?.Invoke(one);
            return one;
        }
        private bool CanUse()
        {
            return _pool.Count > 0;
        }

        public void RecycelOneObject(E one)
        {
            _pool.Enqueue(one);
            SetUnused?.Invoke(one);
        }
        public void RecycleAllObjects()
        {
            _pool.Clear();
            _all_object_list.ForEach((one) => {
                SetUnused?.Invoke(one);
                _pool.Enqueue(one);
            });
        }
        public void ClearPool()
        {
            _pool.Clear();
            _all_object_list.Clear();
        }

        public void ForeachPool(Action<E> SomeHandle)
        {
            if (SomeHandle == null) return;
            _all_object_list.ForEach((one) => {
                SomeHandle(one);
            });
        }
    }
}
