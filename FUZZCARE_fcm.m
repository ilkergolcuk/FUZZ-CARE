function [theta, U, center, obj_fcn] = FUZZCARE_fcm(X,y, cluster_n, options)
for i=1 % parameters and setting
if nargin ~= 3 & nargin ~= 4
	error('Too many or too few input arguments!');
end

data = [X y];

data_n = size(data, 1);     %example size
in_n = size(X, 2);       %feature size
if data_n<in_n
    data = data';
    data_n = size(data, 1);
    in_n = size(data, 2);
end

% Change the following to set default options
default_options = [0.01;   % learning ratio
        0.5;  % lambda2
        1;	% lambda
		100;	% max. number of iteration
		1e-5;	% min. amount of improvement
		0];      % display info or not 

if nargin == 3
	options = default_options;
else
	% If "options" is not fully specified, pad it with default values.
	if length(options) < 5
		tmp = default_options;
		tmp(1:length(options)) = options;
		options = tmp;
	end
	% If some entries of "options" are nan's, replace them with defaults.
	nan_index = find(isnan(options)==1);
	options(nan_index) = default_options(nan_index);
end
alpha = options(1);
lambda2 = options(2);
lambda = options(3);% Lambda1
max_iter = options(4);		% Max. iteration
min_impro = options(5);		% Min. improvement
display = options(6);		% Display info or not


obj_fcn = zeros(max_iter, 2);	% Array for objective function
U = initfcm( cluster_n,data_n); U=U';			% Initial fuzzy partition
end 
% Main loop
% data = (mapminmax(data'))';%need standarlization
X = [ones(data_n,1) X];                       % X is used to compute theta, but data is used for FCM part
center = zeros(cluster_n, in_n+1);            %K*In_n matrix
theta = zeros(in_n+1,cluster_n);              %K*In_n matrix
for o = 1:max_iter
    % update center (K*In_n)
    mf = U'.^2;       % MF matrix after exponential modification
    center = mf*data./(sum(mf,2)*ones(1,in_n+1)); %new center K*In_n
    % update theta  (In_n*K)    
    for k = 1:cluster_n
        U_kx = U(:,k)*ones(1,in_n+1).*X;    % generate U_kx
% -----------------use GD to update theta------------------------
        theta(:,k) = theta(:,k)+2*alpha/(data_n)*(U_kx'*(y-sum(U_kx*theta,2))+lambda2*theta(:,k));
    end
% -----------------end GD---------------------------------------            
    % update U     (dat_n*In_n)
    for k = 1:cluster_n
        norm_XC(:,k) = sum((data - ones(data_n,1)*center(k,:)).^2,2);
    end
    ita_fz = y.*sum(X*theta./( (X*theta).^2 + lambda*norm_XC ) ,2) -1;
    ita_fm = sum(0.5./ ((X*theta).^2+lambda*norm_XC) ,2);
    ita = ita_fz./ita_fm;
    U_fz = 2*y*ones(1,cluster_n).*(X*theta) - repmat(ita,1,cluster_n);
    U_fm = 2*( (X*theta).^2 + lambda*norm_XC );
    % do not update ith row of U if U_fz(i,:) contains negtive values
    Update_row = find(min(U_fz,[],2)>0);
    U(Update_row,:) = U_fz(Update_row,:)./U_fm(Update_row,:);
    % compute loss function
    obj_fcn(o,1) = sum(sum((X*theta.*U-y*ones(1,cluster_n)).^2));
%     obj_fcn(o,2) = 0;
    for k = 1:cluster_n
        obj_fcn(o,2) = obj_fcn(o,2)+ sum((mf(k,:))'.* sum((data - repmat(center(k,:),data_n,1)).^2,2));
    end
%     % avoid overfitting
%         if o>=2
%         if obj_fcn(o,2)>obj_fcn(o-1,2)
%             CostIncreaseIndex = CostIncreaseIndex +1;
%             if CostIncreaseIndex>=6
%                 break
%             end
%         else
%             CostIncreaseIndex = 0;
%         end
%     end
end
iter_n = o;	% Actual number of iterations
obj_fcn = obj_fcn/data_n;
obj_fcn(iter_n+1:max_iter,:) = [];


for i=1 % compute parameters by iteration
%     for i = 1:data_n
%         norm_XC = sum((repmat(data(i,:),cluster_n,1) - center).^2,2);  %cluster_n*1
%         ita_fz(i) = sum( y(i)*X(i,:)*theta./((X(i,:)*theta).^2+lambda*norm_XC(i,:)),2 )-1;
%         ita_fm(i) = sum(0.5./  ((X(i,:)*theta).^2+lambda*norm_XC(i,:)) ,2);
%         ita(i) = ita_fz(i)/ita_fm(i);              
%         for k = 1:cluster_n
%              U_fz(i,k) = 2*y(i)*X(i,:)*theta(:,k)-ita(i);               
%              U_fm(i,k) = 2*( (X(i,:)*theta(:,k))^2 + lambda*norm_XC(i,k) );
%         end
%         if min(U_fz(i,:))>0
%             U(i,:) = U_fz(i,:)./U_fm(i,:);
%         end
%     end  
%     % compute loss function
%     for i = 1:data_n
%         for k = 1:cluster_n
%             obj_fcn(o,1) = obj_fcn(o,1) + (X(i,:)*theta(:,k)*U(i,k)-y(i))^2 ;
%             obj_fcn(o,2) = obj_fcn(o,2) + mf(k,i)*norm(data(i,:)-center(k,:),2)^2;
%         end
%     end
end