%% ==========================================================
%  IMPORT BOTH DATASETS AS AUDIODATASTORES
%  Author: (Your Name)
%  Purpose: To load AudioMNIST and Emotion Speech datasets
%  ==========================================================

clc; clear;

%% STEP 1 — SET YOUR FOLDER PATHS (edit these as per your PC)
audioMNIST_folder = 'C:\Users\admin\Downloads\0-9 numbers\data';  % path to AudioMNIST
emotion_folder    = 'C:\Users\admin\Downloads\Emotion speech dataset\files';  % path to Emotion dataset

%% STEP 2 — CREATE AUDIO DATASTORE FOR AUDIO MNIST
adsAudioMNIST = audioDatastore(audioMNIST_folder, ...
    'FileExtensions', '.wav', ...
    'IncludeSubfolders', true);

n1 = numel(adsAudioMNIST.Files);
fprintf('\n🎙️ AudioMNIST dataset loaded: %d WAV files found in\n%s\n', n1, audioMNIST_folder);

if n1 == 0
    error('❌ No .wav files found in AudioMNIST folder. Please check the path.');
end

%% STEP 3 — CREATE AUDIO DATASTORE FOR EMOTION SPEECH DATASET
adsEmotion = audioDatastore(emotion_folder, ...
    'FileExtensions', '.wav', ...
    'IncludeSubfolders', true);

n2 = numel(adsEmotion.Files);
fprintf('\n🎧 Emotion Speech dataset loaded: %d WAV files found in\n%s\n', n2, emotion_folder);

if n2 == 0
    error('❌ No .wav files found in Emotion dataset folder. Please check the path.');
end

%% STEP 4 — DISPLAY SAMPLE FILES FROM EACH DATASET
fprintf('\n🔹 First 5 AudioMNIST files:\n');
disp(adsAudioMNIST.Files(1:min(5,n1)));

fprintf('\n🔹 First 5 Emotion dataset files:\n');
disp(adsEmotion.Files(1:min(5,n2)));

%% STEP 5 — SAVE BOTH DATASTORES FOR LATER USE
save(fullfile(pwd, 'audioDatastore_AudioMNIST.mat'), 'adsAudioMNIST');
save(fullfile(pwd, 'audioDatastore_Emotion.mat'), 'adsEmotion');

fprintf('\n✅ Both datastores saved successfully in:\n%s\n', pwd);
fprintf('   - audioDatastore_AudioMNIST.mat\n   - audioDatastore_Emotion.mat\n');