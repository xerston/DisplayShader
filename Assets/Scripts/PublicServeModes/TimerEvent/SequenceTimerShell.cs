using System;
using System.Collections.Generic;
using UnityEngine;

namespace Tools.TimerEvent
{
    public class SequenceTimerShell
    {
        #region AddFunction

        private List<Action> Stays = new List<Action>();
        private List<Func<bool>> Checks = new List<Func<bool>>();
        private List<Action> Ends = new List<Action>();
        public SequenceTimerShell AddTimer(Action Stay, float interval, Action End, bool append = true)
        {
            float timer = interval;
            return AddEvent(Stay, () => {
                timer -= Time.deltaTime;
                if (timer < 0)
                {
                    timer = interval;
                    return true;
                }
                return false;
            }, End, append);
        }
        public SequenceTimerShell AddCheck(Action Stay, Func<bool> Check, Action End, bool append = true)
        {
            return AddEvent(Stay, Check, End, append);
        }
        public SequenceTimerShell AddFrame(Action Stay, int frame_count, Action End, bool append = true)
        {
            int count = frame_count;
            return AddEvent(Stay, () => {
                count--;
                if (count <= 0)
                {
                    count = frame_count;
                    return true;
                }
                return false;
            }, End, append);
        }
        //DoAnimFrameDo本质是DoTimerDoSet
        private const float _anim_frame_interval = 1 / 30f;
        public SequenceTimerShell AddAnimFrame(Action Stay, int general_count, Action End, bool append = true)
        {
            float interval = _anim_frame_interval * general_count;
            return AddTimer(Stay, interval, End, append);
        }
        private SequenceTimerShell AddEvent(Action Stay, Func<bool> Check, Action End, bool append)
        {
            if (append)
            {
                Stays.Add(Stay);
                Checks.Add(Check);
                Ends.Add(End);
            }
            else
            {
                Stays.Insert(0, Stay);
                Checks.Insert(0, Check);
                Ends.Insert(0, End);
            }
            return this;
        }

        #endregion

        #region TimerLife

        private Timer _one;
        private int _used_timer_count = 0;
        private bool _ban_start = false;
        public SequenceTimerShell Start(bool is_loop = false, TimerType timer_type = TimerType.Fixed)
        {
            if ((_ban_start && _used_timer_count > 0) || (_one != null && _one.is_pause))
            {
                Debug.LogWarning("当前事件组循环未结束或暂停中，不允许申请计时器");
                return null;
            }

            _ban_start = is_loop;
            _used_timer_count++;
            _one = Timer.GetTimerEvent();
            _one.StartSequence(timer_type, is_loop, Stays, Checks, Ends,
                ()=> {
                    _used_timer_count--;
                    if(_used_timer_count <= 0) _one = null;
                });
            return this;
        }
        public SequenceTimerShell ForceStop(bool trigger_end_handle = true)
        {
            if (_one == null) return null;
            _one.ForceStop(trigger_end_handle);
            _one = null;
            return this;
        }
        public void Play()
        {
            if (_one == null) return;
            _one.is_pause = false;
        }
        public void Pause()
        {
            if (_one == null) return;
            _one.is_pause = true;
        }
        public void SwitchLoop(bool open)
        {
            if (_one == null) return;
            _one.is_loop = open;
        }

        #endregion

        public SequenceTimerShell ClearEventQueue()
        {
            Stays.Clear();
            Checks.Clear();
            Ends.Clear();
            return this;
        }

        public void ResetSequenceQueue()
        {
            _one.ResetSequenceQueue();
        }
    }
}

