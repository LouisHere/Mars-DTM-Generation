基于MRO CTX数据生成DTM地形数据
===
**利用ASP+ISIS软件处理Mars MRO CTX立体像对生成DTM**（更新于2025/03/24）
<br><br>
由于ASP软件仅可在Linux或MacOS系统下运行，如果是用Windows系统，推荐使用Windows Subsystem for Linux（WSL）虚拟环境运行。
<br><br>
本教程所使用Linux Ubuntu 20.04，安装的ASP软件为3.5.0版本，ISIS软件为8.3.0版本。
<br>
分为以下几个步骤：
1. 安装软件
2. 下载CTX立体像对
3. 利用ISIS预处理CTX数据
4. 利用ASP生成CTX DTM
<br>

## 1. 安装软件

### 1.1 安装ASP

Ames Stereo Pipeline（ASP）是一款由美国宇航局（NASA）艾姆斯研究中心开发的的开源软件工具，主要用于处理立体影像数据以生成高分辨率的三维地形模型。该软件特别适用于行星科学领域，能够处理来自不同行星探测任务的数据，包括月球、火星以及其他天体的图像，是目前处理行星、地球光学数据主流使用的摄影测量软件。<br>

按照其网址可下载安装：
    https://stereopipeline.readthedocs.io/en/latest/installation.html

### 1.2 安装ISIS
    在安装完成ASP软件之后，还需要安装
