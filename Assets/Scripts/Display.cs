using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine;
using Tools.TimerEvent;
using Tools.TimerEvent.DoAnim;

public class Display : MonoBehaviour
{
    public static Text DisplayName;
    private void Awake()
    {
        Timer.Init();
        DisplayName = GameObject.Find("Canvas/Text").GetComponent<Text>();
    }

    private SequenceAnim sequenceAnim;
    private void Start()
    {
        sequenceAnim = ObjectDo.GetSequence();
        for (int i = 0;i < transform.childCount;i++)
        {
            GameObject go = transform.GetChild(i).gameObject;
            sequenceAnim.AddCallBack(() => {
                go.SetActive(true);
                DisplayName.text = go.name;
            }).AddInterval(5f).AddCallBack(() => {
                go.SetActive(false);
            });
        }

        sequenceAnim.AddCallBack(() => { Application.Quit(); });
        sequenceAnim.Start();
    }

    private void OnDisable()
    {
        sequenceAnim.KillAnim();
        sequenceAnim = null;
    }
}
