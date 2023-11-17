using System;
using System.Collections.Generic;
using UnityEngine;

namespace Tools.TimerEvent.DoAnim
{
    public enum EaseType
    {
        Linear,
        SinInOut,
        SinOutIn,
        SinOut,
        SinIn,
        BaseNumberIn,
        BaseNumberOut,
        ExponentIn
    }

    public class EaseData
    {
        #region EaseFunction

        private static float GetEaseLinear(float t)
        {
            return t;
        }
        private static float GetEaseSinInOut(float t)
        {
            float x = 0.5f * (float)Math.Sin(Math.PI * t - 0.5f * Math.PI) + 0.5f;
            return x;
        }
        private static float GetEaseSinOutIn(float t)
        {
            float x;
            if (t <= 0.5f)
            {
                x = 0.5f * (float)Math.Sin(Math.PI * t);
            }
            else
            {
                x = -0.5f * (float)Math.Sin(Math.PI * t) + 1f;
            }
            Debug.Log(x);
            return x;
        }
        private static float GetEaseSinOut(float t)
        {
            float x = (float)Math.Sin(0.5f * Math.PI * t);
            return x;
        }
        private static float GetEaseSinIn(float t)
        {
            float x = (float)Math.Sin(0.5f * Math.PI * t - 0.5f * Math.PI) + 1f;
            return x;
        }
        private static float GetEaseBaseNumberIn(float t)
        {
            float x = Mathf.Pow(t, 8);
            return x;
        }
        private static float GetEaseBaseNumberIn(float t, int power)
        {
            float x = Mathf.Pow(t, power);
            return x;
        }
        private static float GetEaseBaseNumberOut(float t)
        {
            float x = -Mathf.Pow(t - 1f, 8) + 1f;
            return x;
        }
        private static float GetEaseBaseNumberOut(float t, int power)
        {
            float x = -Mathf.Pow(t - 1f, power) + 1f;
            return x;
        }
        private static float GetEaseExponentIn(float t)
        {
            float x = (Mathf.Pow(2f, 4f * t) - 1f) / 15f;
            return x;
        }

        #endregion

        private Func<float, float> ForwardEase;
        private Func<float, float> BackwardEase;
        public EaseData(EaseType ease_type)
        {
            SetEaseType(ease_type);
        }

        public Func<float, float> UsedEase;
        private bool forward = true; //当前曲线方向
        public void ChangeEaseDirection()
        {
            if (forward)
            {
                forward = false;
                UsedEase = BackwardEase;
            }
            else
            {
                forward = true;
                UsedEase = ForwardEase;
            }
        }
        public void SetEaseDirection(bool dir)
        {
            if (forward == dir) return;

            if(dir == true)
            {
                UsedEase = ForwardEase;
            }
            else
            {
                UsedEase = BackwardEase;
            }
            forward = dir;
        }

        public void SetEaseType(EaseType ease_type)
        {
            switch (ease_type)
            {
                case EaseType.Linear:
                    ForwardEase = GetEaseLinear;
                    break;
                case EaseType.SinInOut:
                    ForwardEase = GetEaseSinInOut;
                    break;
                case EaseType.SinOutIn:
                    ForwardEase = GetEaseSinOutIn;
                    break;
                case EaseType.SinOut:
                    ForwardEase = GetEaseSinOut;
                    break;
                case EaseType.SinIn:
                    ForwardEase = GetEaseSinIn;
                    break;
                case EaseType.BaseNumberIn:
                    ForwardEase = GetEaseBaseNumberIn;
                    break;
                case EaseType.BaseNumberOut:
                    ForwardEase = GetEaseBaseNumberOut;
                    break;
                case EaseType.ExponentIn:
                    ForwardEase = GetEaseExponentIn;
                    break;
            }

            UsedEase = ForwardEase;
            BackwardEase = (t) => {
                return ForwardEase(1 - t);
            };
        }
    }
}
