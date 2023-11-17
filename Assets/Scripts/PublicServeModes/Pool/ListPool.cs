using System;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Tools.Pool
{
    public class ListPool<E> : IPool<E>
    {
        private List<E> _pool = new List<E>();

        public int Count { get { return _pool.Count; } }
        public Func<E, bool> CanUse; //对象可用的条件
        public Action<E> SetUsed; //设置为 被占用 的方法
        public Action<E> SetUnused; //设置为 可用 的方法
        public Func<E> Generator; //创建对象方法
        public ListPool(Func<E, bool> CanUse,Action<E> SetUsed,Action<E> SetUnused, Func<E> Generator)
        {
            this.CanUse = CanUse;
            this.SetUsed = SetUsed;
            this.SetUnused = SetUnused;
            this.Generator = Generator;
        }

        public E AddOneObject()
        {
            E one = Generator();
            _pool.Add(one);
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
                    _pool.Add(one);
                }
            }
        }

        public E GetOneObject()
        {
            E one = default(E);
            foreach (var item in _pool)
            {
                if (CanUse(item))
                {
                    one = item;
                    SetUsed(one);
                    return one;
                }
            }

            one = Generator();
            SetUsed(one);
            _pool.Add(one);
            return one;
        }

        public void RecycelOneObject(E e)
        {
            SetUnused(e);
        }
        public void RecycleAllObjects()
        {
            foreach (var item in _pool)
            {
                SetUnused(item);
            }
        }
        public void ClearPool()
        {
            _pool.Clear();
        }

        public void ForeachPool(Action<E> SomeHandle)
        {
            if (SomeHandle == null) return;
            _pool.ForEach((one)=> {
                SomeHandle(one);
            });
        }
    }
}
