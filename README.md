**DESCRIPTION**

This gem implements a command line tool for downloading images from a list of urls and stores them on the local harddrive. 

**INSTALLATION**

>git clone git@github.com:VergunDA/file_downloader.git

Change directory to file_downloader

>cd file_downloader

Run bundle install

> bundle install

**USAGE**

Run rake task in command line in project's directory

>rake file_downloader:download_from_file[path_to_file, path_to_download, separator]

**Defaults**

<pre>
path_to_download = /downloads (in the projects root)

separator = ' ' (whitespace)
</pre>

**EXAMPLE OUTPUT**

![This is an image](https://i2.paste.pics/FER2L.png)
