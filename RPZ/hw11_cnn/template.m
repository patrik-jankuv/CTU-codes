% Init MatConvNet framework
MCNPath = './matconvnet-1.0-beta23/matconvnet-1.0-beta23';
run(fullfile(MCNPath, 'matlab/vl_setupnn'))

% load data
load imdb

% for augmentation it is easier to have the original data
imdb.images.data(:,:,1,:) = imdb.images.data(:,:,1,:) + imdb.images.data_mean;

% SCREW THE IMAGES
for i = 1:59000
    if mod(i, 1000) == 0
        disp(i)
    end
    imdb.images.data(:,:,1,i) = reshape(screw_image(reshape(imdb.images.data(:,:,1,i), [28,28])), [28,28,1]);
end
imdb.images.data_mean = mean(imdb.images.data, 4);
imdb.images.data = (imdb.images.data - imdb.images.data_mean) / 255;

% training and validation sets
imdb.images.set = [1 * ones(1, 59000), 2 * ones(1, 1000)];

%% 2. CNNs
% --------------------------------------------------------------------
% adding layers, dropout and max-pooling
clear net;
delete expDir/*

net.layers = {} ;
net.layers{end+1} = struct('name', 'conv1', ...
			   'type', 'conv', ...
			   'weights', {{1*randn(3,3,1,30,'single'), zeros(1, 30,'single')}}, ...
			   'stride', 2, ...
			   'pad', 1) ;
net.layers{end+1} = struct('name', 'relu1', ...
			   'type', 'relu') ;
net.layers{end+1} = struct('name', 'conv1', ...
			   'type', 'conv', ...
			   'weights', {{(1/30)*randn(3,3,30,60,'single'), zeros(1, 60,'single')}}, ...
			   'stride', 1, ...
			   'pad', 0) ;
net.layers{end+1} = struct('name', 'relu1', ...
			   'type', 'relu') ;           
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'max', ...
                           'pool', [2 2], ...
                           'stride', 2, ...
                           'pad', 0);
net.layers{end+1} = struct('name', 'conv1', ...
			   'type', 'conv', ...
			   'weights', {{(1/60)*randn(3,3,60,500,'single'), zeros(1, 500,'single')}}, ...
			   'stride', 1, ...
			   'pad', 0) ;
net.layers{end+1} = struct('name', 'relu1', ...
			   'type', 'relu') ;            
net.layers{end+1} = struct('name', 'full', ...
			   'type', 'conv', ...
			   'weights', {{(1/500)*randn(4,4,500,10,'single'), zeros(1, 10,'single')}}, ...
			   'stride', 1, ...
			   'pad', 0);        
net.layers{end+1} = struct('type', 'softmaxloss') ;


% currently best: objective: 0.087 top1err: 0.018 top5err: 0.001, 
% folder: 0400

net = vl_simplenn_tidy(net);
vl_simplenn_display(net)

[net, info] = cnn_train(net, imdb, @getSimpleNNBatch, 'batchSize', 2000, 'numEpochs', 18, 'expDir', 'expDir', 'learningRate',0.07);   %'plotStatistics', false);
% save your best network
net.layers{end}.type = 'softmax';
save('my_cnn.mat', 'net');