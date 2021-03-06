clear all
close all
clc

% Test PG cell capturing using compatiable scm.
% pSCM+pGCM+SCC+DFS, this is the newest edition!
%
% By: Free Xiong; 2014-08-14

No = 4;
N = [121;121];
[lb, ub, dsys] = ProblemDef(No);
% [lb, ub, lb_par, ub_par, dsys] = ProblemDef_uncertain(No);
samNo = 10;
samTra = 9;

% construct gcm
tic;
[P, scm] = gcm(dsys, lb, ub, N, samNo); % GCM for deterministic system
% [P, scm] = gcm_uncertain(dsys, lb, ub, lb_par, ub_par, N, samNo); % GCM for uncertainity
% [P, scm] = gcm_rand(dsys, lb, ub, N, samNo, samTra); % GCM for random system
time_gcm = toc

% determine persistent group using scc+ccm from gcm
tic;
[pg, gr, type, g] = pg_cells_scc(P); % forward only
time_pg = toc

% determine the domiciles of transient cells and unstable manifolds
tic;
Dm = domicile(pg, gr, g, P);
unstable_mani_id = unstable_manifold(gr,type,P);
time_domi = toc

%% Plot extracted information from GCM
gr_stable = unique(gr(pg==1 & type==1)); % stable group numbers
gr_unstable = unique(gr(pg==1 & type==2));
bnd = ones(size(Dm,1),1);

% unstable manifold start from unstable solutions
PlotCells(find(unstable_mani_id & pg==0),lb,ub,N,'black','EdgeOff');
hold on

% manifolds that separate stable solutions
if length(gr_stable)>1
    for i = 1:length(gr_stable)
        bnd = bnd & gr_stable(i)==Dm(:,gr_stable(i));
    end
    % manifold separate the attraction basin of stable solutions
    PlotCells(find(bnd),lb,ub,N,'cyan','EdgeOff');
end

% stable solutions
for i = 1:length(gr_stable)
    bnd = bnd & gr_stable(i)==Dm(:,gr_stable(i));
    PlotCells(find(gr==gr_stable(i)),lb,ub,N,'red','EdgeOff');
    hold on
end

% unstable solutions
for i = 1:length(gr_unstable)
    PlotCells(find(gr==gr_unstable(i)),lb,ub,N,'blue','EdgeOff');
    hold on
end

%% calculate joint and marginal probability distribution
% p_old = zeros(prod(N),1);
p_old = 1/prod(N)*ones(prod(N),1);
for i = 1:120
    p_new = P'*p_old;
    err(i) = norm(p_new-p_old);
    p_old = p_new;
end
figure
plot(err,'.-')
xlabel('Iteration time')
ylabel('Error')

figure
xc = PlotCells(1:prod(N),lb,ub,N,'blue','EdgeOff');
close

figure
scatter(xc(p_new~=0,1),xc(p_new~=0,2),8,p_new(p_new~=0),'square','filled')
axis([lb(1) ub(1) lb(2) ub(2)])
xlabel('$x_1$')
ylabel('$x_2$')

% calculate marginal probabilily of one dimension
dim = 1; % which dimension to look at
p_marginal = zeros(N(dim),1);
xdim = zeros(N(dim),1);
h = (ub-lb)./N;
for i = 1:N(dim)
    N_others = N;
    N_others(dim) = [];
    xdim(i) = lb(dim) + h(dim)/2 + h(dim)*(i-1); % coordinate along dim direction
    
    % get the cell coordinate along the ith coordinate along dim
    A = cell(length(N),1);
    A{1} = i;
    for j = 1:length(N_others)
        A{j+1} = 1:N_others(j);
    end
    Z = allcomb(A{:});
    for j = 1:size(Z,1)
        z = Z(j,:)';
        cs = ztocell(z,N);
        p_marginal(i) = p_marginal(i) + p_new(cs);
    end
end
figure
indices = 1:length(N);
indices(dim) = [];
plot(xdim,p_marginal*prod(h(indices)),'.-')
xlabel('$x_1$')
ylabel('$p_x$')
set(gca,'XLim',[lb(dim) ub(dim)])

%%
% save duffing_tran_N_100x100.mat
% save plasma_tran_N_30x30x30.mat
% save Auto_duffing_uncertain_N_141x141.mat
% save impact_N_189x189.mat