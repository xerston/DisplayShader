using UnityEngine;
using UnityEngine.Networking;
using System.IO;

public class LoadMapInfo
{
    private string file_path;
    private string check_path;
    public string GetSingleString(string file_name)
    {
        if (Application.platform == RuntimePlatform.WindowsEditor || 
            Application.platform == RuntimePlatform.WindowsPlayer) //如果在编译器或者单机中
        {
            file_path = "file://" + Application.streamingAssetsPath + "/" + file_name;
        }
        else if(Application.platform == RuntimePlatform.Android) //在Android下
        {
            file_path = "jar:file://" + Application.dataPath + "!/assets/" + file_name;
        }
        else if(Application.platform == RuntimePlatform.IPhonePlayer) //在Iphone下
        {
            file_path = "file://" + Application.dataPath + "/Raw/" + file_name;
        }

        //StreamingAssets 文件夹只读,不可写,且只能通过UnityWebRequest/WWW读取
        //使用UnityWebRequest时路径需要加"file://"前缀
        try
        {
            UnityWebRequest request = UnityWebRequest.Get(file_path);
            request.timeout = 100;
            request.SendWebRequest(); //发送读取数据请求
            while (true)
            {
                if (request.downloadHandler.isDone) //是否读取完数据
                {
                    return request.downloadHandler.text;
                }
            }
        }
        catch
        {
            return "";
        }
    }
}
