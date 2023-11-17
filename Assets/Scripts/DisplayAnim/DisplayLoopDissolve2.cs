using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Tools.TimerEvent.DoAnim;

public class DisplayLoopDissolve2 : MonoBehaviour
{
    private SequenceAnim anim;
    private void Start()
    {
        Material mate = GetComponent<Renderer>().sharedMaterial;
        mate.SetFloat("_BurnAmount", 0f);
        anim = ObjectDo.GetSequence().AddInterval(0.2f)
            .AddAnim(ObjectDo.DoFloat(0f, 1f, 4f, (value) => {
                mate.SetFloat("_BurnAmount", value);
            }));
        anim.Start();
    }

    private void OnDisable()
    {
        anim.KillAnim();
        anim = null;
    }
}
