function [G] = LPPLAI(data,outputpath,varargin)

parseObj = inputParser;
parseObj.addRequired('data',@FileCheck);
parseObj.addRequired('outputpath',@outputpathCheck);
parseObj.addParameter('startday',"nothing",@startdayCheck);
parseObj.addParameter('rightdays',100,@rightdaysCheck);
parseObj.addParameter('rightscale',0.15,@rightscaleCheck);
parseObj.addParameter('Tradingday',252,@TradingdayCheck);
parseObj.addParameter('cycle',500,@cycleCheck);
parseObj.addParameter('PopulationSize',200,@PopulationSizeCheck);
parseObj.addParameter('Generations',700,@GenerationsCheck);
parseObj.addParameter('pricegyration',0,@pricegyrationCheck);

parseObj.parse(data, outputpath,varargin{:});

outputpath = parseObj.Results.outputpath;
startday = parseObj.Results.startday;
rightdays = parseObj.Results.rightdays;
rightscale = parseObj.Results.rightscale;
Tradingday = parseObj.Results.Tradingday;
cycle = parseObj.Results.cycle;
PopulationSize = parseObj.Results.PopulationSize;
Generations = parseObj.Results.Generations;
pricegyration = parseObj.Results.pricegyration;

num_table = data; 
num_raw = num_table{:, 2};
text = num_table{:, 1};
DateStrings_raw=text(1:end,1);
if startday == "nothing"
    num = num_raw;

    DateStrings = DateStrings_raw;
else
    startday_datetime = datetime(startday);
    startpoint = find(DateStrings_raw==startday_datetime);
    DateStrings = DateStrings_raw(startpoint:length(DateStrings_raw));
    num = num_raw(startpoint:length(DateStrings_raw));
end

t = datetime(DateStrings);
MatDate = datenum(t); 
price=num;
rightscale = 1 - rightscale;

[SRTPT,DATE_CRASH] = id_SRTPT(MatDate,price,rightdays,rightscale,Tradingday);
idx = length(DateStrings);
END = DateStrings(idx);
END = datenum(END);
ENDPT = find (MatDate == datenum(END));
keep = [SRTPT:1:ENDPT]; 
Date_keep = MatDate(keep);
Date_datetime = datetime(Date_keep,'ConvertFrom','datenum');
formatOut = 'yyyy-mm-dd';
Date_char = datestr(Date_datetime,formatOut);
% Date = cellstr(Date_char);
Price = price(keep);

LogPrice = log(Price);

if pricegyration == 1
    ip_table=readtable(outputpath + "\" +'INITIALVALUE_table.xlsx'); 
    ip = ip_table.Variables;
    G = zeros(cycle,9);  % matrix storing output
    
    parfor i_run=1:cycle
        ip_cycle=[];
        ip_cycle_raw = ip(1+((i_run-1)*PopulationSize):i_run*PopulationSize ,:);
        for ip_cycle_lin = 1:PopulationSize
            if ip_cycle_raw(ip_cycle_lin,:)==[0,0,0,0,0,0,0,0]
            else
                ip_cycle(end+1,:) = ip_cycle_raw(ip_cycle_lin,:);
            end
        end
        if ip_cycle_raw(1,:)==[0,0,0,0,0,0,0,0]
            T = LogPrice; 
            lb=[max(T),-inf,length(T),0.1,-1,4.8,0]; % lower bounds
            ub=[inf,0,inf,0.9,1,13,2*pi]; % upper bounds
            options=gaoptimset('Display','off','PopulationSize',PopulationSize,'Generations',Generations);
            [G0,RMSE]=ga({@LPPLFunctionGA,LogPrice},7,[],[],[],[],lb,ub,[],options);
            if G0(4)>0.9 || G0(4)<0.1 % bounds of beta
                continue;
            end
            G(i_run,:)=[G0,RMSE];  %데이터를 직접 지정해서 넣었음으로 i_mb는 삭제가능
        else
            mw = ip_cycle(1,8);
            ip0 = ip_cycle(:,1:7);
            L = length(LogPrice);   
            WS_max = 30; % maximum window size 
            L_min = L - WS_max; % minimum length of data used in estimation
            T = LogPrice(1:L_min+mw);
            lb=[max(T),-inf,length(T),0.1,-1,4.8,0]; % lower bounds
            ub=[inf,0,inf,0.9,1,13,2*pi]; % upper bounds
            options=gaoptimset('Display','off','PopulationSize',PopulationSize,'Generations',Generations,'InitialPopulation',ip0);
            [G0,RMSE]=ga({@LPPLFunctionGA,LogPrice},7,[],[],[],[],lb,ub,[],options);
            if G0(4)>0.9 || G0(4)<0.1 % bounds of beta
                continue;
            end
            %     G(end+1,:)=[G0,RMSE,mw,i_mb];
            G(i_run,:)=[G0,RMSE,mw];  %데이터를 직접 지정해서 넣었음으로 i_mb는 삭제가능
        end 
    end
    if ip_cycle_raw(1,:)==[0,0,0,0,0,0,0,0]
        if length(G) > 1
            colnames = {'A','B','Tc','beta','C','Omega','Phi','RMSE'};
            LPPL_table = array2table(G);
            LPPL_table.Properties.VariableNames = colnames;
        else
            colnames = {'A','B','Tc','beta','C','Omega','Phi','RMSE'};
             G = ['-','-','-','-','-','-','-','-','-'];
            LPPL_table = array2table(G);
            LPPL_table.Properties.VariableNames = colnames;
        end
    else
        if length(G) > 1
            colnames = {'A','B','Tc','beta','C','Omega','Phi','RMSE'};
            LPPL_table = array2table(G);
            LPPL_table.Properties.VariableNames = colnames;
        else
            colnames = {'A','B','Tc','beta','C','Omega','Phi','RMSE'};
            G = ['-','-','-','-','-','-','-','-','-'];
            LPPL_table = array2table(G);
            LPPL_table.Properties.VariableNames = colnames;
        end
    end

else
    T = LogPrice;
    G = zeros(cycle,8);  % matrix storing output
    parfor  i_run=1:cycle
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 2) Estimate LPPL parameters with Genetic Algorithm given the initial values
            % Outputs of this step: matrix 'G'
            % Each row of 'G' is one parameter set of LPPL, and its corresponding
            % RMSE and window size
        %%%%%%%%%%%%%%%%%%%%%%%%%%%    
        lb=[max(T),-inf,length(T),0.1,-1,4.8,0]; % lower bounds
        ub=[inf,0,inf,0.9,1,13,2*pi]; % upper bounds
        %options = optimoptions('ga','Display','off','PopulationSize',PopulationSize,'Generations',Generations,'UseParallel', true, 'UseVectorized', false);
        options = optimoptions('ga','Display','off','PopulationSize',PopulationSize,'Generations',Generations);
        [G0,RMSE]=ga({@LPPLFunctionGA,LogPrice},7,[],[],[],[],lb,ub,[],options);
        if G0(4)>0.9 || G0(4)<0.1 % bounds of beta
            continue;
        end
        G(i_run,:)=[G0,RMSE];  %데이터를 직접 지정해서 넣었음으로 i_mb는 삭제가능
    end

    if length(G) > 1
        colnames = {'A','B','Tc','beta','C','Omega','Phi','RMSE'};
        LPPL_table = array2table(G);
        LPPL_table.Properties.VariableNames = colnames;
    else
        colnames = {'A','B','Tc','beta','C','Omega','Phi','RMSE'};
        G = ['-','-','-','-','-','-','-','-'];
        LPPL_table = array2table(G);
        LPPL_table.Properties.VariableNames = colnames;
    end
    writetable(LPPL_table,outputpath);

end

% Check input outputpath
function OK = FileCheck(data)
    
    if isempty(data)
        error(message('data is empty'));

    else
        OK = true;

    end

function OK = outputpathCheck(outputpath)
    
    if isempty(outputpath)
        error(message('outputpath is empty'));

    else
        OK = true;

    end

function OK = startdayCheck(startday)
    
    if isempty(startday)
        error(message('startday is empty'));

    else
        OK = true;

    end

function OK = rightdaysCheck(rightdays)
    
    if isempty(rightdays)
        error(message('rightdays is empty'));

    else
        OK = true;

    end
    
function OK = rightscaleCheck(rightscale)
    
    if isempty(rightscale)
        error(message('rightscale is empty'));

    else
        OK = true;

    end
    
function OK = TradingdayCheck(Tradingday)

    if isempty(Tradingday)
        error(message('Tradingday is empty'));

    else
        OK = true;

    end

function OK = cycleCheck(cycle)
    
    if isempty(cycle)
        error(message('cycle is empty'));

    else
        OK = true;

    end

function OK = PopulationSizeCheck(PopulationSize)

if isempty(PopulationSize)
    error(message('PopulationSize is empty'));

else
    OK = true;

end
    
function OK = GenerationsCheck(Generations)

if isempty(Generations)
    error(message('Generations is empty'));

else
    OK = true;

end


function OK = pricegyrationCheck(pricegyration)

if isempty(pricegyration)
    error(message('pricegyration is empty'));

else
    OK = true;

end

function [SRTPT, DATE_CRASH] = id_SRTPT(MatDate,price,Right_days,Right_scale,Tradingday)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%  find a series of crash%%%%%%%%%%%%%%%%%%%%%%%%%%
    I_CRASH = zeros(size(MatDate)); % I_CRASH: id for crash (0: no crash, 1: crash)
    DATE_CRASH = zeros(size(MatDate)); % DATE_CRASH: date for crash (0: no crash, some number: crash date)
    PERCENT_DROP = zeros(size(MatDate));  % PERCENT_DROP: the percentage drop from critical price to lowest price after the crash. (0: no crash, some number: percentage drop)
    Left_days = Tradingday;  % The peak of critical time is higher than any peak prior to 262 days
    
    
    for i = 1:length(MatDate)  % 모든 기간에 대해서 peak를 조사. i를 기준으로 262일 이전과 60일 이후의 가격 peak관련 정의 검증
        if i-Left_days>0  %263일부터 이 명령어를 실행. i일로 부터 262이전 동안 가장 높은 가격을 찾는다.
            max_prior = max(price(i-Left_days:i-1));  %max prior는 현재 검색하고 있는 검색창(Left_days)에서 가장높은 값을 의미한다. 
        elseif i>1 %262일 이전부터 이 명령어를 실행. i일 동안 최대값을 찾는다. 
            max_prior = max(price(1:i-1)); 
        else  % i=1. 즉, 첫째날이면 그날은 max가격으로 간주한다.
            max_prior = max(price(i));  
        end
            
        if i+Right_days<length(MatDate)  % 특정 i날에서 60일을 더한 값이 전체 데이터 기간보다 작다면, 아래 세가지 시행
            max_post = max(price(i+1:i+Right_days));    % crash라 여기는 i시점 이후 60일간 max가격 확인. 이는 혹시 우리가 찾은 임계시점 가격보다 뒤에서 높은 가격이 있는지 한번더 확인 하는데 사용.  
            drop_post = find(price(i+1:i+Right_days)<Right_scale*price(i));  %현 i시점의 가격에서 20%보다 더 낮은 가격이 임계시점후 60일 이내에 있으면 그값의 위치를 반환한다. 임계시점의 정의 중 60일이내에 20%떻어졌는지 확인하는 용으로 사용된다
            min_post = min(price(i+1:i+Right_days));  % crash라 여기는 i시점 이후 60일간 min가격 확인. 나중에 임계시점가격보다 최대 몇%나 떨어졌는지 확인하는데 사용
        elseif i+1<length(MatDate)  % 데이터 마지막 60일기간부터 적용. 
            max_post = max(price(i+1:end));
            drop_post = find(price(i+1:end)<Right_scale*price(i));
            min_post = min(price(i+1:end));
        else  %최후의 데이터 시점은 자신의 값을 각각 반환한다 
            max_post = max(price(end));
            drop_post = find(price(end)<Right_scale*price(i));
            min_post = min(price(end));
        end            
        
        if (max_prior< price(i)) && (~isempty(drop_post)) && (max_post<price(i)) %Critical time의 가격 조건--> 첫번째 조건: 과거(262일이전) 최대 값이 현재값보다 작음, 
                                                                                 %두번째 조건: 60일 이내에 20%이상 떨어졌음, 세번째 조건: i시점이후 60일동안 현재 가격보다 높은 가격이 없다
            I_CRASH(i) = 1;  %이 가격은 I_CRASH에 임계시점으로서 1로 표기해 둔다. 
            DATE_CRASH(i) = MatDate(i);  %이 시점은 임계시점으로서 DATE_CRASH란에 해당 날짜를 기입해 둔다. 
            PERCENT_DROP(i) = (1 - min_post/price(i))*100;  %60일이내 최소 가격대비 해당 임계시점 가격에서 최대 몇% 떨어졌는지를 반환한다.   
        end
    end
    DATE_CRASH = DATE_CRASH(DATE_CRASH~=0);  %임계시점 날짜 들만 남긴다. 
    PERCENT_DROP = PERCENT_DROP(PERCENT_DROP~=0);   % percentage drop이 있는 값만 남긴다. 

 %%%%%%%%%%%%%%%%%%%%%%%%%%  select among a series of crash%%%%%%%%%%%%%%%%%%%%%%%%%%
    if length(DATE_CRASH) > 0
        CT=datetime(DATE_CRASH,'ConvertFrom','datenum');% id_SRTPT에서 찾은 임계시점을 우선 CT에 저장
        idx = length(CT);
        CT = CT(idx);
        CT = datenum(CT); % 날짜를 고유값으로 바꾸어 줌
        id_crash = find(MatDate == CT);   %선택된 임계시점인 날을 전체 기간에서 찾아 id_crash에 해당 위치(행)를 반환
        [M,I] = min(price(id_crash:length(MatDate)));  %해당임계시점 임계시점에서 붕괴된후 최소 가격점을 LPPL모델의 시작 포인트로 선정. 
                                                 % (M=min price, I=해당 값이 이전임계시점부터 얼마뒤에 떨어져있는지 위치를 반환)
    else
        [M,I] = min(price(1:length(MatDate)));
        id_crash = 1;
        CT = 1;
    end

    SRTPT = id_crash + I - 1;   % LPPL모델에 사용할 데이터 시작포인트. 전체 데이터기간에서 몇번째 행부터가 우리가 사용하고자 하는 위치인지 알려줌
                                 % 최저 값의 위치를 반환

function E = LPPLFunctionGA(a, LogPrice)

y = LogPrice;  %종속변수
l=length(y);
x=(1:1:l)';  %시간 축
Y=a(1)+(a(2).*(a(3)-x).^a(4)).*(1+a(5).*cos(a(6).*log(a(3)-x)+a(7)));
D=y-real(Y);  %residual
E=((1/l)*sum(D.^2))^0.5;       %RMSE