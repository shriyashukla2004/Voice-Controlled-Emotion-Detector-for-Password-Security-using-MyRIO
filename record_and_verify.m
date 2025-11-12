%% record_and_verify.m — mic -> WAV -> verify_user_minimal
clear; clc; close all;

% --- settings you can change ---
CLAIMED_USER = "13";      % your enrolled/authorized speaker id
REC_SECONDS  = 1.0;       % duration to record
FS           = 48000;     % must match your training extractor sample rate

% --- paths ---
load('config_paths.mat');                          %#ok<LOAD>
outDir = fullfile(PROJECT_ROOT,'outputs','runtime');
if ~isfolder(outDir), mkdir(outDir); end
wavFile = fullfile(outDir, sprintf('trial_%s_%s.wav', CLAIMED_USER, datestr(now,'HHMMSS')));

% --- record ---
disp("🎙️  Speak now...");
recObj = audiorecorder(FS, 16, 1);
recordblocking(recObj, REC_SECONDS);
x = getaudiodata(recObj);
% simple safety: normalize and light DC removal
x = x - mean(x);  x = x ./ max(1e-9, max(abs(x)));

audiowrite(wavFile, x, FS);
fprintf("💾 Saved: %s (%.2f sec)\n", wavFile, numel(x)/FS);

% --- verify ---
result = verify_user_minimal(wavFile, CLAIMED_USER);
disp(result);

% --- quick visualization ---
figure('Color','w','Position',[100 100 900 300]);
t = (0:numel(x)-1)/FS;
plot(t, x); grid on; xlabel('Time (s)'); ylabel('Amplitude');
title(sprintf('Recorded signal — claim=%s | accept=%s | pred=%s', ...
      result.claimedUser, string(result.accept), result.predictedUser));
