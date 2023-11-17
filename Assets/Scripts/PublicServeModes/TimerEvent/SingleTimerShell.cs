using System;
using UnityEngine;

namespace Tools.TimerEvent
{
    public class SingleTimerShell
    {
        #region SetFunction

        public Action Stay;
        public Func<bool> Check;
        public Action End;
        public SingleTimerShell SetTimer(Action Stay, float interval, Action End)
        {
            float timer = 0;
            return SetEvent(Stay,
                () => {
                    timer += Time.deltaTime;
                    if (timer >= interval)
                    {
                        timer = 0;
                        return true;
                    }
                    return false;
                }, End);
        }
        public SingleTimerShell SetRecordTimer(Action<float> Stay, float interval, Action End)
        {
            float timer = 0;
            return SetEvent(
                () => {
                    Stay?.Invoke(timer);
                },
                () => {
                    timer += Time.deltaTime;
                    if (timer >= interval)
                    {
                        timer = 0;
                        return true;
                    }
                    return false;
                }, End);
        }
        public SingleTimerShell SetCheck(Action Stay, Func<bool> Check, Action End)
        {
            return SetEvent(Stay, Check, End);
        }
        public SingleTimerShell SetFrame(Action Stay, int frame_count, Action End)
        {
            int count = frame_count;
            return SetEvent(Stay, () => {
                count--;
                if (count <= 0)
                {
                    count = frame_count;
                    return true;
                }
                return false;
            }, End);
        }
        //DoAnimFrameDo本质是DoTimerDoSet
        private const float _anim_frame_interval = 1 / 30f;
        public SingleTimerShell SetAnimFrame(Action Stay, int general_count, Action End)
        {
            float interval = _anim_frame_interval * general_count;
            return SetTimer(Stay, interval, End);
        }
        public SingleTimerShell SetEvent(Action Stay, Func<bool> Check, Action End)
        {
            this.Stay = Stay;
            this.Check = Check;
            this.End = End;
            return this;
        }

        #endregion

        #region TimerLife

        private Timer _one;
        private int _used_timer_count = 0;
        private bool _ban_start = false;
        public SingleTimerShell Start(bool is_loop = false, TimerType timer_type = TimerType.Fixed)
        {
            if ((_ban_start && _used_timer_count > 0) || (_one != null && _one.is_pause))
            {
                Debug.LogWarning("当前事件组循环未结束或暂停中，不允许申请计时器");
                return null;
            }

            _ban_start = is_loop;
            _used_timer_count++;
            _one = Timer.GetTimerEvent();
            _one.StartSingle(timer_type, is_loop, Stay, Check, End,
                () => {
                    _used_timer_count--;
                    if (_used_timer_count <= 0) _one = null;
                });
            return this;
        }
        public SingleTimerShell ForceStop(bool trigger_end_handle = true)
        {
            if (_one == null) return this;
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

        #region DynamicChange

        public void DynamicAddHandle(Action Stay, Action End)
        {
            if (_one == null) return;
            _one.AddStayEnd(Stay, End);
        }
        public void DynamicRemoveHandle(Action Stay, Action End)
        {
            if (_one == null) return;
            _one.RemoveStayEnd(Stay, End);
        }
        public void DynamicReplaceCheck(Func<bool> Check)
        {
            if (_one == null) return;
            _one.ReplaceCheck(Check);
        }

        #endregion
    }
}
