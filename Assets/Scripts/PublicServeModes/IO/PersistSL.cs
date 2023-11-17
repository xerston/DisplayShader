using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;

public class PersistSL : SingletonBehaviour<PersistSL>
{
    protected override void MoreInit()
    {
        InitPath();
    }
    private string _persist_path;
    private string _streaming_path;
    private void InitPath()
    {
        _persist_path = GetPersistentFilePath();
        _streaming_path = GetStreamingFilePath();
    }
    private string GetStreamingFilePath()
    {
        string pre = "file://";
#if UNITY_EDITOR
        pre = "file://";
#elif UNITY_ANDROID
        pre = "";
#elif UNITY_IPHONE
	    pre = "file://";
#endif
        string path = pre + Application.streamingAssetsPath + "/";
        return path;
    }
    private string GetPersistentFilePath()
    {
        string pre = "file://";
#if UNITY_EDITOR || UNITY_STANDALONE_WIN
        pre = "file:///";
#elif UNITY_ANDROID
        pre = "file://";
#elif UNITY_IPHONE
        pre = "file://";
#endif
        string path = pre + Application.persistentDataPath + "/";
        return path;
    }

    public void StartStreamCopy(string file_name, Action EndHandle)
    {
        StartCoroutine(StreamCopyToPersist(file_name, EndHandle));
    }
    private IEnumerator StreamCopyToPersist(string file_name, Action EndHandle)
    {
        //streaming目录不支持用io函数拷贝
        string src = _streaming_path + file_name;
        string des = Application.persistentDataPath + "/" + file_name;
        UnityWebRequest request = UnityWebRequest.Get(src);
        yield return request.SendWebRequest();
        if (!request.isNetworkError)
        {
            FileStream des_fs;
            if (File.Exists(des))
            {
                des_fs = File.OpenWrite(des);
                des_fs.SetLength(0);
            }
            else
            {
                des_fs = File.Create(des);
            }
            des_fs.Write(request.downloadHandler.data, 0, request.downloadHandler.data.Length);
            des_fs.Flush();
            des_fs.Close();
            EndHandle?.Invoke();
        }
        else
        {
            Debug.Log("web error:" + request.error);
        }
    }

    public bool PersistFileExist(string file_name)
    {
        return File.Exists(Application.persistentDataPath + "/" + file_name);
    }

    #region Texture

    public void LoadOneTexture(string file_url, Action<Texture2D> SingleLoadHandle)
    {
        file_url = _persist_path + file_url;
        StartCoroutine(LoadImage(file_url, SingleLoadHandle));
    }
    public void LoadFolderTextures(string folder_url, Action<Texture2D> EndHandle)
    {
        folder_url = _persist_path + folder_url;
        string[] file_pathes = Directory.GetFiles(folder_url);
        List<string> path_list = new List<string>();
        foreach (string path in file_pathes)
        {
            string path_ext = Path.GetExtension(path);
            if (path_ext == ".png" || path_ext == ".jpg")
            {
                path_list.Add(path);
            }
        }
        path_list.ForEach((one) => {
            StartCoroutine(LoadImage(one, EndHandle));
        });
    }
    private IEnumerator LoadImage(string full_path, Action<Texture2D> EndHandle)
    {
        UnityWebRequest request = UnityWebRequest.Get(full_path);
        DownloadHandlerTexture tex_download_handler = new DownloadHandlerTexture(true);
        request.downloadHandler = tex_download_handler;
        yield return request.SendWebRequest();
        if (!request.isNetworkError)
        {
            EndHandle?.Invoke(tex_download_handler.texture);
        }
        else
        {
            Debug.Log("web error:" + request.error);
        }
    }

    #endregion

    #region Text

    public void LoadOneText(string file_name, Action<String> EndHandle)
    {
        file_name = _persist_path + file_name;
        StartCoroutine(LoadText(file_name, EndHandle));
    }
    private IEnumerator LoadText(string full_path, Action<String> EndHandle)
    {
        UnityWebRequest request = UnityWebRequest.Get(full_path);
        yield return request.SendWebRequest();
        if (!request.isNetworkError)
        {
            EndHandle?.Invoke(request.downloadHandler.text);
        }
        else
        {
            Debug.Log("web error:" + request.error);
        }
    }
    public void SaveText(string file_name, byte[] save_bytes)
    {
        string des = Application.persistentDataPath + "/" + file_name;
        //Debug.Log(des);
        FileStream des_fs = File.OpenWrite(des);
        des_fs.SetLength(0);
        des_fs.Write(save_bytes, 0, save_bytes.Length);
        des_fs.Flush();
        des_fs.Close();
    }

    #endregion
}
