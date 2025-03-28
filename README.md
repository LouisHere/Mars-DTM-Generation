基于MRO CTX数据生成DTM地形数据
===
Updated by Lejun Lu and Huaquan Yang, on 2025/03/28

<br>
主要利用ASP+ISIS软件处理Mars MRO CTX立体像对（6 m分辨率），生成20 m分辨率的地形数据（DTM）。由于ASP软件仅可在Linux或MacOS系统下运行，如果是用Windows系统，推荐使用Windows Subsystem for Linux（WSL）虚拟环境运行。本教程所使用Linux Ubuntu 20.04，安装的ASP软件为3.5.0版本，ISIS软件为8.3.0版本。本教程所用的CTX测试数据已上传至： https://zenodo.org/records/15100257
<br><br>

主要分为以下几个步骤：
1. 安装软件
2. 下载CTX立体像对
3. 基本处理：利用ISIS预处理CTX数据
4. 基本处理：利用ASP生成CTX DTM
5. 进阶处理：CASP-GO批处理
<br>

## 1. 安装软件

### 1.1 安装ASP

Ames Stereo Pipeline（ASP）是一款由美国宇航局（NASA）艾姆斯研究中心开发的的开源软件工具，主要用于处理立体影像数据以生成高分辨率的三维地形模型。该软件特别适用于行星科学领域，能够处理来自不同行星探测任务的数据，包括月球、火星以及其他天体的图像，是目前处理行星、地球光学数据主流使用的摄影测量软件。按照其网址指示下载安装：https://stereopipeline.readthedocs.io/en/latest/installation.html

（1）从github上下载ASP 3.5.0安装包：https://github.com/NeoGeographyToolkit/StereoPipeline/releases<br>
（2）解压安装包：
```
tar xvf StereoPipeline-3.4.0-2024-06-19-x86_64-Linux.tar.bz2
```
（3）修改bash环境变量：在～/.bashrc文件中添加以下内容（"/path/to/StereoPipeline/bin"替代为实际的解压路径）
```
export PATH=${PATH}:/path/to/StereoPipeline/bin
```
（4）测试是否安装成功：
```
stereo --help
```
<br>

### 1.2 安装ISIS3

在安装完成ASP软件之后，还需要安装Integrated Software for Imagers and Spectrometers v3（ISIS3）软件，用于预处理非地球的立体影像数据。按照其网址指示下载安装：https://github.com/DOI-USGS/ISIS3#installation

（1）推荐使用conda进行安装，建立isis虚拟环境：
```
# Create conda environment, then activate it.
conda create -n isis 
conda activate isis
# Add conda-forge and usgs-astrogeology channels
conda config --env --add channels conda-forge
conda config --env --add channels usgs-astrogeology
# Check channel order
conda config --show channels
```
（2）下载并安装ISIS3:
```
conda install -c usgs-astrogeology isis
```
（3）修改isis虚拟环境的环境变量：指定isisdata路径，用于下载遥感影像的相机参数等关键数据。
```
conda activate isis
conda env config vars set ISISROOT=$CONDA_PREFIX ISISDATA=[your data path]
conda deactivate
conda activate isis
```
（4）从ISIS3下载所需的相机参数等数据：

```
# 先更新ISIS3
conda update -c usgs-astrogeology isis

# 如果空间足够，可以将所有相机类型的参数文件都下载，约占用2TB
downloadIsisData all $ISISDATA

# 更推荐下载要用的相机类型即可，节省下载时间，例如下载该教程中要用到的MRO CTX相机（mro）
downloadIsisData mro $ISISDATA
downloadIsisData base $ISISDATA
```
<br>

## 2. 下载MRO CTX立体像对

MRO CTX（Mars Reconnaissance Orbiter Context Camera）是由NASA的火星勘测轨道飞行器携带的一种相机，用于拍摄火星表面的高分辨率黑白图像。MRO CTX立体影像分辨率为6 m/pixel，幅宽约30 km。<br>

目前仅试过使用NASA Mars Orbital Data Explorer (ODE)进行下载，需要根据设置要求筛选所需的CTX数据。网址如下：https://ode.rsl.wustl.edu/mars/index.aspx<br>

另外，可以从MarsSI网站上，查看CTX Stereo的分布图，网址如下：https://marssi.univ-lyon1.fr/MarsSI/<br>

**这部分仍有待进一步挖掘，如何批量下载符合要求的CTX立体影像。**<br>
**可能的方式：（1）用wget命令或其他批处理下载软件，从JPL网站批量下载，http://planetarydata.jpl.nasa.gov/img/data/mro/ctx; (2) 从MarsSI网站上将适合范围的CTX数据加入购物车，批量下载，但该步骤需要注册帐号且帐号需要审核。**
<br><br>

## 3. 基本处理：利用ISIS预处理CTX数据

下载好CTX数据后，放置进同一文件夹内。本教程使用p07_003621_1980_xi_18n133w.img和p10_005032_1980_xi_18n_133w.img作为例子。

（1）数据转化：由原始数据IMG转为ISIS可处理的cub格式。
```
mroctx2isis from=p07_003621_1980_xi_18n133w.img to=p07_003621_1980_xi_18n133w.cub
mroctx2isis from=p10_005032_1980_xi_18n133w.img to=p10_005032_1980_xi_18n133w.cub
```
（2）添加Spice：Spice为航空器的导航参数和相机的标定参数，即摄影测量所使用的内外方位元素，由ISIS3提供。
```
spiceinit from=p07_003621_1980_xi_18n133w.cub # 如没有下载ISIS3的数据，或提示缺少某文件，可以添加参数 web=true 解决
spicefit from=p10_005032_1980_xi_18n133w.cub 
spiceinit from=p10_005032_1980_xi_18n133w.cub
spicefit from=p10_005032_1980_xi_18n133w.cub
```
（3）辐射校正：对影像进行辐射校正以去除光照影响。
```
ctxcal from=p07_003621_1980_xi_18n133w.cub to=p07_003621_1980_xi_18n133w.cal.cub
ctxcal from=p10_005032_1980_xi_18n133w.cub to=p10_005032_1980_xi_18n133w.cal.cub
```
（4）条纹校正（可选）：去除部分数据中存在的条纹状噪声。经初步测试，即使无该噪声的影像用ctxevenodd处理后，对DTM结果无影响。因此建议在批处理时设置为统一使用。
```
ctxevenodd from=p07_003621_1980_xi_18n133w.cal.cub to=p07_003621_1980_xi_18n133w.cal.eo.cub
ctxevenodd from=p10_005032_1980_xi_18n133w.cal.cub to=p10_005032_1980_xi_18n133w.cal.eo.cub
```
（5）绘制投影影像（可选）：将影像由相机坐标系投影至特定的地图坐标系下。
```
cam2map from=p07_003621_1980_xi_18n133w.cal.eo.cub to=p07_003621_1980_xi_18n133w.cal.eo.proj.cub
cam2map from=p10_005032_1980_xi_18n133w.cal.eo.cub to=p10_005032_1980_xi_18n133w.cal.eo.proj.cub
```
cam2map的具体参数请看：https://isis.astrogeology.usgs.gov/8.1.0/Application/presentation/Tabbed/cam2map/cam2map.html<br><br>
**如需拼接请保证不同影像的分辨率一致!**
<br><br>

## 4. 基本处理：利用ASP生成CTX DTM
(1) cam2map4stereo.py：将校正后的cub文件，生成带有地理编码的立体影像*.map.cub，用于后续的立体影像匹配获取地形信息。
```
cam2map4stereo.py p07_003621_1980_xi_18n133w.cal.eo.cub p10_005032_1980_xi_18n133w.cal.eo.cub
```
(2) parallel_stereo：利用摄影测量方法（影像特征点匹配）生成高程点云（Point Cloud, PC），"results/out"是结果输出的路径和名字，可根据自己需要修改。--pixres可以设置影像分辨率单位，例如mpp为meter per pixels。
```
parallel_stereo p07_003621_1980_xi_18n133w.cal.eo.map.cub p10_005032_1980_xi_18n133w.cal.eo.map.cub results/out 
```
（3）point2dem：将生成的点云（out-PC.tif）栅格化成DTM，使用-s设置输出DTM的分辨率，分辨率单位根据上一步--pixres来确定，可以自行设置。--orthoimage为输出正射影像。
```
point2dem -r mars --stereographic --auto-proj-center results/out-PC.tif -s 20 --orthoimage results/out-L.tif
```
<br>

## 5. 进阶处理：基于CASP-GO处理生成高质量DTM
由UCL PhD.Tao Yu提出的CASP-GO方法（Tao
