% Runscript Matlab DBA
% 
% Holger Teichgraeber
% July 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear all
clc

%% Test 1 - Provided and adapted from original matlab file

n_seq =5;
length_seq=24;

sequences = {};
sequences{n_seq}=[];
mean_euc = zeros(length_seq,1);
for i=1:n_seq
    length = length_seq;
    sequences{i}=rand(1,length);
    mean_euc = mean_euc + sequences{i}';
end
mean_dba=DBA(sequences);
mean_euc=mean_euc/n_seq;

%% plot test 1
figure()
hold all
grey=0.3;
for i=1:n_seq
    plot(sequences{i},'Color',[grey grey grey])
    plot(mean_dba,'r')
    plot(mean_euc,'b')
end
title('Test 1 - random data')
plotfixer

%% Test 2 - 

ca_data = load('ca_2015_orig.txt');
ger_data = load('GER_2015_elPrice.txt');

% INPUT
data = ca_data;
ind = linspace(1,10,10); % indices of data considered

data = reshape(data',24,365);
data = data(:,ind);

days = {};
days{size(data,2)} = [];
for i=1:size(data,2)
    days{i} = data(:,i);
end
mean_dba_data=DBA(days);
mean_euc_data=mean(data,2);


%% plot test 2
figure()
hold all
grey=0.3;
for i=1:size(data,2)
    plot(days{i},'Color',[grey grey grey])
    plot(mean_dba_data,'r')
    plot(mean_euc_data,'b')
end
title('Test 2 ')
plotfixer

%% simple implementation of kmeans_dtw_dba:

k=3;
data= ca_data;
data = reshape(data',24,365);

% initial random assignment of days to cluster

% assign sequences for each cluster

% calculate average for each cluster

% for number of iterations && ~converged
    % calculate dtw distance of each day to each cluster average
    % reassign days to cluster
    % calcualte new average














