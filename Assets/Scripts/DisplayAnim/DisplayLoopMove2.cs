using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tools.TimerEvent.DoAnim;

public class DisplayLoopMove2 : MonoBehaviour
{
    private SequenceAnim anim;
    private void OnEnable()
    {
        Vector3 target = transform.position + new Vector3(0f, 1f, 0f);
        SingleAnim singleAnim = transform.DoMove(target, 2f).SetLoop(0, LoopType.Bound);
        anim = ObjectDo.GetSequence().AddInterval(0.2f).AddAnim(singleAnim);
        anim.Start();
    }

    private void OnDisable()
    {
        anim.KillAnim();
        anim = null;
    }
}
