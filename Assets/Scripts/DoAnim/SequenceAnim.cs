using System;
using System.Collections.Generic;
using UnityEngine;

namespace Tools.TimerEvent.DoAnim
{
    public class SequenceAnim
    {
        #region Construction

        public SequenceAnim(SequenceTimerShell timer)
        {
            _timer = timer;
        }

        #endregion

        #region AddAnim

        private List<SingleAnim> _anim_list = new List<SingleAnim>();
        public SequenceAnim AddAnim(SingleAnim single_anim, bool append = true)
        {
            if (single_anim == null) return null;

            _anim_list.Add(single_anim);
            single_anim.SetAutoKill(true);
            single_anim.KillAnim();
            single_anim.CopyEventGroup(out Action Stay, out Func<bool> Check, out Action End);
            AddCallBack(()=> {
                // single_anim.RefreshStart();
                single_anim.ResetAnim();
            });
            _timer.AddCheck(Stay, Check, End, append);
            return this;
        }
        public SequenceAnim AddCallBack(Action End, bool append = true)
        {
            _timer.AddCheck(End, ()=> { return true; }, null, append);
            return this;
        }
        public SequenceAnim AddInterval(float interval, bool append = true)
        {
            _timer.AddTimer(null, interval, null, append);
            return this;
        }

        #endregion

        #region Timer

        private SequenceTimerShell _timer;
        private bool _killed = false;
        public void Start(TimerType timer_type = TimerType.Fixed)
        {
            if (_allow_play) return;
            _allow_play = true;
            if (_killed) return;
            AddCallBack(() => {
                if (!_auto_kill)
                {
                    Pause();
                    _allow_play = false;
                }
                else
                {
                    _killed = true;
                }
            });

            _timer.Start(false, timer_type);
            _timer.SwitchLoop(!_auto_kill); //不循环代表自动销毁
        }
        private bool _allow_play = false;
        public void Play()
        {
            if (!_allow_play) return;
            if (_killed) return;
            _timer.Play();
        }
        public void Pause()
        {
            if (_killed) return;
            _timer.Pause();
        }
        public void KillAnim()
        {
            if (_killed) return;
            _timer.ForceStop(false);
            _killed = true;
        }

        private bool _auto_kill = true;
        public SequenceAnim SetAutoKill(bool auto_kill)
        {
            if (_killed) return this;
            _auto_kill = auto_kill;
            return this;
        }

        public void Restart()
        {
            if (_killed) return;
            _allow_play = true;
            _anim_list.ForEach((one) => {
                one.ResetAnim();
            });
            _timer.ResetSequenceQueue();
            _timer.Play();
        }

        #endregion
    }
}

