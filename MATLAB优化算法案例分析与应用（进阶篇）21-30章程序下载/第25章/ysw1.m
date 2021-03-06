%*************细菌觅食优化算法***************
%%%%%%%%%%%%-----BF0算法-----%%%%%%%%%%%%%%%
clc; clear;  close all
warning off
feature jit off  % 加速代码执行
%-----初始化参数-----
bounds = [-5.12, 5.12;-5.12, 5.12]; % 函数变量范围
p = 2;   % 搜索范围的维度
s = 26;  % 细菌的个数
Nc = 50; % 趋化的次数
Ns = 4;  % 趋化操作中单向运动的最大步数
C(:,1) = 0.001*ones(s,1);    % 翻转选定方向后，单个细菌前进的步长
Nre = 4;     % 复制操作步骤数
Ned = 2;     % 驱散(迁移)操作数
Sr = s/2;    % 每代复制（分裂）数
Ped = 0.25;  % 细菌驱散(迁移)概率
d_attract = 0.05;         % 吸引剂的数量
ommiga_attract = 0.05;    % 吸引剂的释放速度
h_repellant = 0.05;       % 排斥剂的数量
ommiga_repellant = 0.05;  % 排斥剂的释放速度
for i = 1:s               % 产生初始细菌个体的位置
    P(1,i,1,1,1) = -5.12 + rand*10.24;
    P(2,i,1,1,1) = -5.12 + rand*10.24;
end
%----细菌趋药性算法循环开始
%---- 驱散(迁移)操作开始
for l = 1:Ned
	%-----复制操作开始
    for k = 1:Nre
        %-----趋化操作(翻转或游动)开始
        for j = 1:Nc
            %-----对每一个细菌分别进行以下操作
            for i = 1:s
                %-----计算函数J(i,j,k,l)，表示第i个细菌在第l次驱散第k次
                %--------复制第j次趋化时的适应度值
                J(i,j,k,l) = fitness(P(:,i,j,k,l));
                %-----修改函数，加上其它细菌对其的影响
                Jcc = sum(-d_attract*exp(-ommiga_attract*((P(1,i,j,k,l)-...
                    P(1,1:26,j,k,l)).^2+(P(2,i,j,k,l)-P(2,1:26,j,k,l)).^2)))+...
                    sum(h_repellant*exp(-ommiga_repellant*((P(1,i,j,k,l)-...
                    P(1,1:26,j,k,l)).^2+(P(2,i,j,k,l)-P(2,1:26,j,k,l)).^2)));
                J(i,j,k,l) = J(i,j,k,l) + Jcc;
                %----保存细菌目前的适应度值，直到找到更好的适应度值取代之
                Jlast = J(i,j,k,l);
                %-----翻转，产生一个随机向量C(i),代表翻转后细菌的方向
                Delta(:,i) = (2*round(rand(p,1))-1).*rand(p,1);
                % PHI表示翻转后选择的一个随机方向上前进
                PHI = Delta(:,i)/sqrt(Delta(:,i)'*Delta(:,i));
                %-----移动，向着翻转后细菌的方向移动一个步长，并且改变细菌的位置
                P(:,i,j+1,k,l) = P(:,i,j,k,l) + C(i,k)*PHI;
                %-----计算细菌当前位置的适应度值
                J(i,j+1,k,l) = fitness(P(:,i,j+1,k,l));
                %-----游动-----
                m = 0;         % 给游动长度计数器赋初始值
                while(m < Ns)  % 未达到游动的最大长度，则循环
                    m = m + 1;
                    % 新位置的适应度值是否更好？如果更好，将新位置的适应度值
                    % 存储为细菌i目前最好的适应度值
                    if(J(i,j+1,k,l)<Jlast)
                        Jlast = J(i,j+1,k,l);  % 保存更好的适应度值
                        % 在该随机方向上继续游动步长单位,修改细菌位置
                        P(:,i,j+1,k,l) = P(:,i,j+1,k,l) + C(i,k)*PHI;
                        % 重新计算新位置上的适应度值
                        J(i,j+1,k,l) = fitness(P(:,i,j+1,k,l));
                    else
                        % 否则，结束此次游动
                        m = Ns;
                    end
                end
                J(i,j,k,l) = Jlast;   % 更新趋化操作后的适应度值
                
            end                       % 如果i<N，进入下一个细菌的趋化，i=i+1
            %-----如果j<Nc，此时细菌还处于活跃状态，进行下一次趋化，j=j+1----->Jlast
            x = P(1,:,j,k,l);
            y = P(2,:,j,k,l);
            clf
            plot(x,y,'h')           % h表示以六角星绘图
            set(gcf,'color',[1,1,1])
            axis([-5,5,-5,5]);      % 设置图的坐标图
            pause(.1)               % 暂停0.1秒后继续
        end
        %---下面进行复制操作
        %-----复制-----
        %-----根据所给的k和l的值，将每个细菌的适应度值按升序排序
        Jhealth = sum(J(:,:,k,l),2);        % 给每个细菌设置健康函数值
        [Jhealth,sortind] = sort(Jhealth);  % 按健康函数值升序排列函数
        P(:,:,1,k+1,l) = P(:,sortind,Nc+1,k,l);
        C(:,k+1) = C(sortind,k);
        %-----将代价小的一半细菌分裂成两个，代价大的一半细菌死亡
        for i = 1:Sr
            % 健康值较差的Sr个细菌死去，Sr个细菌分裂成两个子细菌，保持个体总数的s一致性
            P(:,i+Sr,1,k+1,l) = P(:,i,1,k+1,l);
            C(i+Sr,k+1) = C(i,k+1);
        end
        %-----如果k<Nre，转到(3)，进行下一代细菌的趋化
    end
	%-----趋散，对于每个细菌都以Ped的概率进行驱散，但是驱散的细菌群体的总数
	%--------保持不变，一个细菌被驱散后，将被随机重新放置到一个新的位置
    for m = 1:s
        % 产生随机数，如果既定概率大于该随机数，细菌i灭亡，随机产生新的细菌i
        if(Ped > rand)
            P(1,m,1,1,1) = -5.12 + rand*10.24;
            P(2,m,1,1,1) = -5.12 + rand*10.24;
        else
            P(:,m,1,1,l+1) = P(:,m,1,Nre+1,l);% 未驱散的细菌
        end
    end
end    % 如果l<Ned，转到(2)，否则结束
%-输出最优结果值
reproduction = J(:,1:Nc,Nre,Ned);       % 每个细菌最小的适应度值
[Jlastreproduction,O] = min(reproduction,[],2);
[BestY,I] = min(Jlastreproduction)
Pbest = P(:,I,O(I,:),k,l)

    
    
    
    
    
    
