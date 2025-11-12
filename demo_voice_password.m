function demo_voice_password
% Minimal GUI for Voice Password (Speaker Verification)
% - Dropdown to choose claimed user
% - Record & Verify (auto-fallback to prerecorded WAV if no mic)
% - Pick WAV & Verify
%
% Requires:
%   - config_paths.mat  (defines PROJECT_ROOT, AUDIO_MNIST_ROOT)
%   - outputs/models/speaker_model.mat (your trained model)
%   - verify_user_minimal.m (already working in your project)

    %% ---------- setup ----------
    load('config_paths.mat','PROJECT_ROOT','AUDIO_MNIST_ROOT');

    % Load model to fetch the list of enrolled users
    M = load(fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat'));
    if isfield(M,'speakerMdl')
        users = string(unique(M.speakerMdl.ClassNames,'stable'));
    else
        users = string(unique(M.bestModel.ClassNames,'stable'));
    end

    % UI
    S = uifigure('Name','Voice Password Demo','Position',[240 180 600 320]);
    uilabel(S,'Text','Claimed User:','Position',[24 280 100 22]);
    dd = uidropdown(S,'Items',cellstr(users),'Value',users(1), ...
        'Position',[120 280 120 22]);

    status = uilabel(S,'Text','Ready','FontWeight','bold', ...
        'Position',[260 280 320 22]);

    ax = uiaxes(S,'Position',[24 60 552 200]);
    title(ax,'Waveform'); xlabel(ax,'Time (s)'); ylabel(ax,'Amplitude'); grid(ax,'on');

    uibutton(S,'Text','Record & Verify','Position',[120 20 150 30], ...
        'ButtonPushedFcn',@(btn,~)doRecordVerify());
    uibutton(S,'Text','Pick WAV & Verify','Position',[330 20 150 30], ...
        'ButtonPushedFcn',@(btn,~)doPickVerify());

    % ---- nested helpers -------------------------------------------------
    function doRecordVerify()
        claim = string(dd.Value);
        dev = audiodevinfo;
        FS = 48000; secs = 1.0; % <-- keep FS consistent with training
        if isempty(dev.input)
            updateStatus("No mic found. Using prerecorded file.", 'warn');
            f = findOneFileFor(claim);
            if f == ""
                updateStatus("No files for user "+claim, 'err'); return;
            end
            [x,fs] = audioread(f); showWave(ax,x,fs);
            res = verify_user_minimal(f, claim);
            showDecision(ax, res); return;
        end

        updateStatus("Recording...", 'info');
        recObj = audiorecorder(FS,16,1);
        recordblocking(recObj, secs);
        x = getaudiodata(recObj);
        x = x - mean(x); x = x ./ max(1e-9, max(abs(x)));
        showWave(ax,x,FS);

        outDir = fullfile(PROJECT_ROOT,'outputs','runtime');
        if ~isfolder(outDir), mkdir(outDir); end
        fp = fullfile(outDir, sprintf('trial_%s_%s.wav', claim, datestr(now,'HHMMSS')));
        audiowrite(fp, x, FS);

        try
            res = verify_user_minimal(fp, claim);
            showDecision(ax, res);
        catch ME
            updateStatus("Verify error: "+ME.message, 'err');
        end
    end

    function doPickVerify()
        claim = string(dd.Value);
        [fn,fp] = uigetfile({'*.wav','WAV Files (*.wav)'}, 'Pick WAV');
        if isequal(fn,0), return; end
        f = fullfile(fp,fn);
        try
            [x,fs] = audioread(f); showWave(ax,x,fs);
            res = verify_user_minimal(f, claim);
            showDecision(ax, res);
        catch ME
            updateStatus("Verify error: "+ME.message, 'err');
        end
    end

    function f = findOneFileFor(claim)
        S2 = dir(fullfile(AUDIO_MNIST_ROOT,'**',"*_"+claim+"_*"+".wav"));
        if isempty(S2), f = ""; else, f = fullfile(S2(1).folder,S2(1).name); end
    end

    function showWave(ax,x,fs)
        if size(x,2)>1, x = mean(x,2); end
        t = (0:numel(x)-1)/fs;
        plot(ax,t,x); grid(ax,'on');
        xlabel(ax,'Time (s)'); ylabel(ax,'Amplitude');
        drawnow;
    end

    function showDecision(ax,res)
        if res.accept
            ttl = sprintf('Claim=%s | Pred=%s | ✅ ACCEPTED', res.claimedUser, res.predictedUser);
            color = [0 0.55 0];
            updateStatus("ACCESS GRANTED", 'ok');
        else
            ttl = sprintf('Claim=%s | Pred=%s | 🔐 DENIED',   res.claimedUser, res.predictedUser);
            color = [0.8 0 0];
            updateStatus("ACCESS DENIED", 'warn');
        end
        title(ax, ttl, 'Color', color);
    end

    function updateStatus(msg, kind)
        switch lower(kind)
            case 'ok',    status.FontColor = [0 0.55 0];
            case 'info',  status.FontColor = [0 0 0];
            case 'warn',  status.FontColor = [0.85 0.4 0];
            case 'err',   status.FontColor = [0.8 0 0];
            otherwise,    status.FontColor = [0 0 0];
        end
        status.Text = char(msg);
        drawnow;
    end
end
