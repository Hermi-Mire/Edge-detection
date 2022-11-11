clc,clear,close all

% image_src = imread('01.jpeg');
image_src = imread('D:\File\Program\matlab\EdgeDetection\obm.png');
[m, n, dim] = size(image_src);

%%================图像预处理========================
image_gray=rgb2gray(image_src);

%% 直方图均值化
image_histeq = histeq(image_gray,256);

%%=================边缘检测=======================
%% 高斯平滑降噪
sigma = 0.5;
%使用标准差为1的二维高斯平滑核对灰度图像进行滤波
image_gray2 = imgaussfilt(image_gray,sigma);
%% 锐化
% sharp=[-1 -1 -1,-1 8.5 -1,-1 -1 -1];
% sharp=[1 1 1,1 -7 1,1 1 1];
% sharp=[0 -1 0,-1 4.5 -1,0 -1 0];
% sharp=[0 -1 -1 -1 0,-1 1 1 1 -1,-1 1 5 1 -1,-1 1 1 1 -1,0 -1 -1 -1 0];
% image_sharp=conv2(double(image_gray),sharp,'same');

figure;
    subplot(1,4,1);
        imshow(image_src);%原图
        title('原始图像');
    subplot(1,4,2);
        imshow(image_gray);
        title('灰度图像');
    subplot(1,4,3);
        imshow(image_histeq);
        title('均值化');
%     subplot(1,4,4);
%         imshow(image_gray2);
%         title('锐化图像');


%% Sobel算子
I2 = double(image_gray2);

sobel = [1 2 1,0 0 0,-1 -2 -1];
I1_y = conv2(I2,sobel,'same');
I1_x = conv2(I2,sobel','same');
theta = zeros(m,n);
sector = zeros(m,n);
for x = 1:(m-1)
    for y = 1:(n-1)
        I2(x,y) = (I1_y(x,y)^2 + I1_x(x,y)^2)^0.5;%几何平均求梯度幅值
        theta(x,y) = atand(I1_y(x,y) / I1_x(x,y));%反正切求梯度方向
        tem = theta(x,y);
        
        if (tem >= 22.5) && (tem < 67.5)
            sector(x,y) =  0;    
        elseif (tem >= -22.5) && (tem < 22.5)
            sector(x,y) =  3;    
        elseif (tem >= -67.5) && (tem < -22.5)
            sector(x,y) =  2;    
        else
            sector(x,y) =  1;    
        end
    end
end

%% 非极大值抑制

canny1=zeros(m,n);
for x = 2:(m-1)
    for y = 2:(n-1)
        %先置零，若邻域四个方向有更大值，更新
        canny1(x,y) = 0;
        if 0 == sector(x,y) %右上左下
            if (I2(x,y) >= I2(x+1,y+1)) && (I2(x,y) > I2(x-1,y-1))
                canny1(x,y) = I2(x,y);
            end
        elseif 1 == sector(x,y) %垂直方向
            if (I2(x,y) >= I2(x,y+1)) && (I2(x,y) > I2(x,y-1))
                canny1(x,y) = I2(x,y);
            end
        elseif 2 == sector(x,y) %左上右下
            if (I2(x,y) >= I2(x-1,y+1)) && (I2(x,y) > I2(x+1,y-1))
                canny1(x,y) = I2(x,y);
            end
        elseif 3 == sector(x,y) %水平方向
            if (I2(x,y) >= I2(x-1,y)) && (I2(x,y) > I2(x+1,y))
                canny1(x,y) = I2(x,y);
            end
        end
    end
end

%% 双阈值检测

ratio = 2;%高低阈值比
canny2 = zeros(m,n);
bin = zeros(m,n);
lowTh = 50;
for y = 2:(m-1)
    for x = 2:(n-1)
        if canny1(y,x)<lowTh %低阈值
            canny2(y,x) = 0;
            bin(y,x) = 0;
        elseif canny1(y,x)>ratio*lowTh %高阈值
            canny2(y,x) = canny1(y,x);
            bin(y,x) = 1;
        else %介于之间的看其8领域有没有高于高阈值的，有则可以为边缘
            tem = [canny1(y-1,x-1), canny1(y-1,x), canny1(y-1,x+1);
                canny1(y,x-1), canny1(y,x), canny1(y,x+1);
                canny1(y+1,x-1), canny1(y+1,x), canny1(y+1,x+1)];
            temMax = max(tem);
            if temMax(1) > ratio*lowTh
                canny2(y,x) = temMax(1);
                bin(y,x) = 1;
                %高阈值减半查找
            elseif temMax(1) > ratio*lowTh/2
                canny2(y,x) = temMax(1);
                bin(y,x) = 1;
            else
                canny2(y,x) = 0;
                bin(y,x) = 0;
            end
        end
    end
end

%% Matlab自带Canny算子
I2_3 = edge(double(image_gray),'canny'); 

%% 绘图
figure;
    subplot(3,2,1);
        imshow(uint8(I1_y));%原图
        title('y轴方向卷积');
    subplot(3,2,2);
        imshow(uint8(I1_x));
        title('x轴方向卷积'); 
    subplot(3,2,3);
        imshow(uint8(I2));
        title('梯度幅值图');
    subplot(3,2,4);
        imshow(uint8(canny2));
        title('非最大值抑制结果');
    subplot(3,2,5);
        imshow(bin);
        title('My Canny');
    subplot(3,2,6);
        imshow(I2_3);
        title('Matlab canny算子分割结果');        
        
        
        
        

