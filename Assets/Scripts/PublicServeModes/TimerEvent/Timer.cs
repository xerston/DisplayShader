using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tools.Pool;

namespace Tools.TimerEvent
{
    public enum TimerType
    {
        Normal,
        Fixed,
        Late,
        End,
    }
    public class Timer : MonoBehaviour
    {
        #region TimerQueue

        protected static QueuePool<Timer> _timer_queue;
        //private static int timer_count = 0;
        public static void Init()
        {
            _timer_queue = new QueuePool<Timer>(
                (one) => { one.is_used = true; },
                (one) => { one.is_used = false; },
                () => {
                    //timer_count++;
                    Timer one = GameObject.Find("ServeModes/Public").AddComponent<Timer>();
                    one.enabled = false;
                    //one.timer_code = timer_count;
                    return one;
                });
        }

        public static Timer GetTimerEvent()
        {
            return _timer_queue.GetOneObject();
        }

        public static void DestroyAllTimers()
        {
            _timer_queue.ForeachPool(one => Destroy(one));
            _timer_queue.ClearPool();
        }

        #endregion

        #region TimerSelect

        public bool is_used = false;
        public bool is_loop = false;
        public bool is_pause = false;

        protected Action Stay;
        protected Func<bool> Check;
        protected Action End;
        protected Action TimerEndHandle;
        //private int timer_code;
    
        private Coroutine _coro;
        private Queue<Action> Stays = new Queue<Action>();
        private Queue<Func<bool>> Checks = new Queue<Func<bool>>();
        private Queue<Action> Ends = new Queue<Action>();
        public void StartSequence(TimerType timer_type, bool is_loop, List<Action> Stays,
            List<Func<bool>> Checks, List<Action> Ends, Action TimerEndHandle)
        {
            //Debug.Log("queue init " + timer_code);
            this.is_loop = is_loop;
            //要内容复制，仅引用会造成多个计时器同时使用外部队列
            Stays.ForEach((one)=> {
                this.Stays.Enqueue(one);
            });
            Checks.ForEach((one)=> {
                this.Checks.Enqueue(one);
            });
            Ends.ForEach((one)=> {
                this.Ends.Enqueue(one);
            });
            this.TimerEndHandle = TimerEndHandle;

            SelectTimerType(timer_type);
            if (timer_type != TimerType.Late)
            {
                _coro = StartCoroutine(SequenceCheck());
            }
            else
            {
                _coro = StartCoroutine(LateSequenceCheck());
            }
        }
        public void StartSingle(TimerType timer_type, bool is_loop, Action Stay,
            Func<bool> Check, Action End, Action TimerEndHandle)
        {
            //Debug.Log("single init " + timer_code);
            this.is_loop = is_loop;
            this.Stay = Stay;
            this.Check = Check;
            this.End = End;
            this.TimerEndHandle = TimerEndHandle;

            SelectTimerType(timer_type);
            if (timer_type != TimerType.Late)
            {
                _coro = StartCoroutine(SingleCheck());
            }
            else
            {
                _coro = StartCoroutine(LateSingleCheck());
            }
        }
        private void SelectTimerType(TimerType timer_type)
        {
            if (timer_type == TimerType.Fixed)
            {
                _yield_wait = _wait_fixed;
            }
            else if (timer_type == TimerType.End)
            {
                _yield_wait = _wait_end;
            }
            else //Late或Normal
            {
                _yield_wait = null;
            }
        }

        #endregion

        #region DynamicChangeHandle

        public void AddStayEnd(Action Stay, Action End)
        {
            this.Stay += Stay;
            this.End += End;
        }
        public void RemoveStayEnd(Action Stay, Action End)
        {
            this.Stay -= Stay;
            this.End -= End;
        }
        public void ReplaceCheck(Func<bool> Check)
        {
            this.Check = Check;
        }

        #endregion

        #region TimerCheck

        private YieldInstruction _yield_wait = null;
        private WaitForFixedUpdate _wait_fixed = new WaitForFixedUpdate();
        private WaitForEndOfFrame _wait_end = new WaitForEndOfFrame();
        private WaitWhile _wait_while_pause;
        private WaitForSeconds _wait_0s = new WaitForSeconds(0);
        private void Awake()
        {
            _wait_while_pause = new WaitWhile(() => { return is_pause; });
        }
        private int _sequence_index = 0;
        private IEnumerator SequenceCheck()
        {
            bool check_result;
            do
            {
                _sequence_index = 0;
                for (; _sequence_index < Checks.Count; _sequence_index++)
                {
                    Stay = Stays.Dequeue();
                    Stays.Enqueue(Stay);
                    Check = Checks.Dequeue();
                    Checks.Enqueue(Check);
                    End = Ends.Dequeue();
                    Ends.Enqueue(End);

                    //Debug.Log("checks count " + CheckHandles.Count + "code == " + timer_code);
                    while (true)
                    {
                        yield return _yield_wait;
                        Stay?.Invoke();
                        check_result = Check?.Invoke() ?? true;
                        if (is_pause) yield return _wait_while_pause;
                        if (check_result) break;
                    }
                    //Debug.Log("checks count " + CheckHandles.Count + "code == " + timer_code);
                    End?.Invoke();
                }
            } while (is_loop);

            yield return _wait_0s; //StopCorotine后协程遇到yield才会真正停止，否则继续执行
            //计时结束
            EndTimerEvent();
        }
        private IEnumerator SingleCheck()
        {
            bool check_result;
            do
            {
                while (true)
                {
                    yield return _yield_wait;
                    Stay?.Invoke();
                    check_result = Check?.Invoke() ?? true;
                    if (is_pause) yield return _wait_while_pause;
                    if (check_result) break;
                }
                End?.Invoke();
            } while (is_loop);

            yield return _wait_0s; //StopCorotine后协程遇到yield才会真正停止，否则继续执行
            //计时结束
            EndTimerEvent();
        }

        #endregion

        #region LateTimerCheck

        private IEnumerator LateSequenceCheck()
        {
            do
            {
                _sequence_index = 0;
                for (; _sequence_index < Checks.Count; _sequence_index++)
                {
                    Stay = Stays.Dequeue();
                    Stays.Enqueue(Stay);
                    Check = Checks.Dequeue();
                    Checks.Enqueue(Check);
                    End = Ends.Dequeue();
                    Ends.Enqueue(End);

                    enabled = true;
                    while (true)
                    {
                        yield return _yield_wait;
                        if (is_pause)
                        {
                            enabled = false;
                            yield return _wait_while_pause;
                            enabled = true;
                        }
                        if (_trigger_end)
                        {
                            yield return _yield_wait;
                            break;
                        }
                    }
                }
            } while (is_loop);

            yield return _wait_end; //StopCorotine后协程遇到yield才会真正停止，否则继续执行
            //计时结束
            EndTimerEvent();
        }
        private IEnumerator LateSingleCheck()
        {
            do
            {
                enabled = true;
                while (true)
                {
                    yield return _yield_wait;
                    if (is_pause)
                    {
                        enabled = false;
                        yield return _wait_while_pause;
                        enabled = true;
                    }
                    if (_trigger_end)
                    {
                        yield return _yield_wait;
                        break;
                    }
                }
            } while (is_loop);

            yield return _wait_end; //StopCorotine后协程遇到yield才会真正停止，否则继续执行
            //计时结束
            EndTimerEvent();
        }
        private bool _trigger_end = false;
        private void LateUpdate()
        {
            if (!_trigger_end)
            {
                Stay?.Invoke();
                if (Check?.Invoke() ?? true)
                {
                    _trigger_end = true;
                }
            }
            else
            {
                End?.Invoke();
                _trigger_end = false;
                enabled = false;
            }
        }

        #endregion

        #region ResetSequenceQueue

        public void ResetSequenceQueue()
        {
            if (_sequence_index >= Checks.Count - 1) return;

            //Debug.Log(_sequence_index);
            //Debug.Log(Checks.Count - 1);
            int rest_count = Checks.Count - _sequence_index - 1;
            for (int i = 0;i < rest_count;i++)
            {
                Stay = Stays.Dequeue();
                Stays.Enqueue(Stay);
                Check = Checks.Dequeue();
                Checks.Enqueue(Check);
                End = Ends.Dequeue();
                Ends.Enqueue(End);
            }
            _sequence_index = -1;
        }

        #endregion

        #region TimerEnd

        private void EndTimerEvent()
        {
            if (!is_used) return;

            is_loop = false;
            is_pause = false;

            //Debug.Log("clear " + timer_code);
            Stay = null;
            Check = null;
            End = null;
            Stays.Clear();
            Checks.Clear();
            Ends.Clear();

            TimerEndHandle?.Invoke();
            TimerEndHandle = null;
            _coro = null;
            _timer_queue.RecycelOneObject(this);
        }
        private void EndUpdateTimer()
        {
            Action TempEndHandle = End;
            EndTimerEvent();
            TempEndHandle?.Invoke();
        }
        public void ForceStop(bool trigger_end_handle)
        {
            //Debug.Log("switch off " + timer_code);
            StopCoroutine(_coro);
            _trigger_end = false;
            enabled = false;
            if (trigger_end_handle)
            {
                EndUpdateTimer();
            }
            else
            {
                EndTimerEvent();
            }
        }

        #endregion
    }
}
