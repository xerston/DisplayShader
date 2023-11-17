using System;
using UnityEngine;

namespace Tools.TimerEvent.DoAnim
{
    public enum LoopType
    {
        Bound,
        Repeat,
        Increase
    }

    public class MotionData
    {
        public Vector3 start;
        public Vector3 offset;
        public bool is_to_target = true;
        public Vector3 to_target_end; //仅在ToTarget模式下有用
    }
    public class AnimParaMeters
    {
        public float interval;
        public Action SetCurrentStart;
        public Action<float> GetData;
        public TimerType timer_type;
    }

    public class SingleAnim
    {
        #region Construction

        private MotionData _motion_data;
        private float _interval;
        private Action SetCurrentStart;
        private Action<float> GetData;

        private Action PrepareEnd;
        private Action KeepAddData;
        private Action ReduceLoopTimes;
        private float _current_t = 0;
        public SingleAnim(MotionData motion_data, AnimParaMeters paras)
        {
            _timer = new SingleTimerShell();
            _ease_data = new EaseData(EaseType.Linear);

            _motion_data = motion_data;
            _motion_data.to_target_end = _motion_data.start + _motion_data.offset;
            _interval = paras.interval;
            SetCurrentStart = paras.SetCurrentStart;
            GetData = paras.GetData;

            PrepareEnd = () => {
                _current_t = _interval;
                GetData(GetEaseData());
                _current_t = 0;
            };
            KeepAddData = () => { _motion_data.start += _motion_data.offset; };
            ReduceLoopTimes = () => { _loop_count--; };
            SetLoop(1, LoopType.Bound);

            _timer.SetCheck(
                () => {
                    GetData(GetEaseData());
                },
                () => {
                    _current_t += Time.deltaTime;
                    if (_current_t >= _interval)
                    {
                        PrepareEnd();
                        LoopEndHandle?.Invoke();

                        if (_loop_count <= 0)
                        {
                            if (!_auto_kill)
                            {
                                Pause();
                                EndHandle?.Invoke();
                                return false;
                            }
                            else
                            {
                                _killed = true;
                                EndHandle?.Invoke();
                                return true;
                            }
                        }
                        return false;
                    }
                    return false;
                }, null).Start(false, paras.timer_type);
        }
        private float GetEaseData()
        {
            return _ease_data.UsedEase(_current_t / _interval);
        }

        #endregion

        #region Timer

        private SingleTimerShell _timer;
        private bool _killed = false;
        public void Play()
        {
            if (_loop_count <= 0) return;
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
        public SingleAnim SetAutoKill(bool auto_kill)
        {
            if (_killed) return this;
            _auto_kill = auto_kill;
            return this;
        }

        public void CopyEventGroup(out Action Stay, out Func<bool> Check, out Action End)
        {
            Stay = _timer.Stay;
            Check = _timer.Check;
            End = _timer.End;
        }

        #endregion

        #region SetLoop

        private int _loop_times = 1;
        private int _loop_count = 1;
        public SingleAnim SetLoop(int loop_times, LoopType loop_type)
        {
            if(loop_times <= 0)
            {
                SetEndless(true);
            }
            else
            {
                SetEndless(false);
                _loop_times = loop_times;
                _loop_count = _loop_times;
            }

            if (loop_type == LoopType.Bound)
            {
                SetForward(false);
                SetKeepAddData(false);
            }
            else if(loop_type == LoopType.Increase)
            {
                SetForward(true);
                SetKeepAddData(true);
            }
            else if (loop_type == LoopType.Repeat)
            {
                SetForward(true);
                SetKeepAddData(false);
            }

            return this;
        }
        private void SetEndless(bool endless)
        {
            PrepareEnd -= ReduceLoopTimes;
            if (!endless)
            {
                PrepareEnd += ReduceLoopTimes;
            }
        }
        private void SetForward(bool forward)
        {
            PrepareEnd -= _ease_data.ChangeEaseDirection;
            if (!forward)
            {
                PrepareEnd += _ease_data.ChangeEaseDirection;
            }
        }
        private void SetKeepAddData(bool keep_data)
        {
            PrepareEnd -= KeepAddData;
            if (keep_data)
            {
                PrepareEnd += KeepAddData;
            }
        }

        #endregion

        #region SetCallBack

        private Action LoopEndHandle;
        public SingleAnim OnLoopEnd(Action LoopEndHandle)
        {
            this.LoopEndHandle = LoopEndHandle;
            return this;
        }

        private Action EndHandle;
        public SingleAnim OnEnd(Action EndHandle)
        {
            this.EndHandle = EndHandle;
            return this;
        }

        #endregion

        #region TargetOrOffset

        public SingleAnim ToTarget()
        {
            if (!_motion_data.is_to_target)
            {
                _motion_data.offset -= _motion_data.start;
                _motion_data.is_to_target = true;
            }
            return this;
        }
        public SingleAnim ToOffset()
        {
            if (_motion_data.is_to_target)
            {
                _motion_data.offset += _motion_data.start;
                _motion_data.is_to_target = false;
            }
            return this;
        }

        #endregion

        #region Restart

        private bool _is_forward = true;
        public SingleAnim RestartByDirection(bool is_forward)
        {
            SetCurrentStart();
            ResetAnim();
            if (_is_forward != is_forward)
            {
                _motion_data.offset = -_motion_data.offset;
                _is_forward = is_forward;
            }
            Play();
            return this;
        }

        public void ResetAnim()
        {
            _loop_count = _loop_times;
            SetProgress(0);
            _ease_data.SetEaseDirection(true);
        }

        #endregion

        #region OtherFunction

        private EaseData _ease_data;
        public SingleAnim SetEaseType(EaseType ease_type)
        {
            _ease_data.SetEaseType(ease_type);
            return this;
        }

        public SingleAnim SetProgress(float percent)
        {
            if (percent < 0f) percent = 0f;
            if (percent > 1f) percent = 1f;
            _current_t = percent * _interval;
            return this;
        }

        public void RefreshStart()
        {
            if (_motion_data.is_to_target)
            {
                SetCurrentStart();
                _motion_data.offset = _motion_data.to_target_end - _motion_data.start;
            }
            else
            {
                SetCurrentStart();
            }
        }

        public void ChangeTarget(Vector3 target_value, bool to_target = true, float interval = -1f)
        {
            SetCurrentStart();
            _motion_data.offset = target_value - _motion_data.start;
            _motion_data.is_to_target = true;
            if (!to_target) ToOffset();
            if (interval > 0) _interval = interval;
            SetProgress(0);
        }

        #endregion
    }
}
