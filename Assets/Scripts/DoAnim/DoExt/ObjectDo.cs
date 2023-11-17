using System;

namespace Tools.TimerEvent.DoAnim
{
    public static partial class ObjectDo
    {
        #region DoValue

        public static SingleAnim DoFloat(float start, float target_value,
            float time, Action<float> Handle, TimerType timer_type = TimerType.Fixed)
        {
            MotionData motion_data = new MotionData();
            motion_data.start.x = start;
            motion_data.offset.x = target_value - motion_data.start.x;

            AnimParaMeters paras = new AnimParaMeters();
            paras.interval = time;
            paras.SetCurrentStart = () => { motion_data.start += motion_data.offset; };
            paras.GetData = (p) => { Handle?.Invoke(motion_data.start.x + motion_data.offset.x * p); };
            paras.timer_type = timer_type;

            return new SingleAnim(motion_data, paras);
        }

        #endregion

        #region DoDivideEvent

        public static void DoFrameDivideEvent(Action[] handles)
        {
            if (handles.Length <= 0) return;

            handles[0]?.Invoke();
            SequenceTimerShell timer = new SequenceTimerShell();
            for (int i = 1;i < handles.Length;i++)
            {
                timer.AddFrame(handles[i], 1, null);
            }
            timer.Start();
        }

        #endregion

        #region Sequence

        public static SequenceAnim GetSequence()
        {
            SequenceTimerShell timer = new SequenceTimerShell();
            SequenceAnim sequence_anim = new SequenceAnim(timer);
            return sequence_anim;
        }

        #endregion
    }
}

