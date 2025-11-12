function demo_voice_password_legacy
% Legacy (figure/uicontrol) GUI for Voice Password verification.
% Works even when uifigure isn't available.
% Requires:
%   - config_paths.mat (PROJECT_ROOT, AUDIO_MNIST_ROOT)
%   - outputs/models/speaker_model.mat
%   - verify_user_minimal.m

    % ---- Setup & data ----
    load('config_paths.mat','PROJECT_ROOT','AUDIO_MNIST_ROOT');
    M = load(fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat'));
    if isfield(M,'speakerMdl')
        users = string(unique(M.speakerMdl.ClassNames,'stable'));
    else
        users = string(unique(M.bestModel.ClassNames,'stable'));
    end
    users = cellstr(users);

    % ---- Figure ----
    h.fig = figure('Name','Voice Password Demo (Legacy)',...
        'NumberTitle','off','Color','w','Position',[200 180 640 360]);

    % ---- Controls ----
    uicontrol(h.fig,'Style','text','String','Claimed User:',...
        'HorizontalAlignment','left','BackgroundColor','w',...
        'Position',[20 320 100 20],'FontWeight','bold');

    h.dd = uicontrol(h.fig,'Style','popupmenu','String',users,...
        'Position',[120 320 120 22]);

    h.status = uicontrol(h.fig,'Style','text','String','Ready',...
        'HorizontalAlignment','left','BackgroundColor','w',...
        'Position',[260 320 360 20],'FontWeight','bold');

    h.ax = axes('Parent',h.fig,'Position',[0.08 0.18 0.88 0.55]);
    title(h.ax,'Waveform'); xlabel(h.ax,'Time (s)'); ylabel(h.ax,'Amplitude'); grid(h.ax,'on');

    h.btnRec = uicontrol(h.fig,'Style','pushbutton','String','Record & Verify',...
        'Position',[160 20 140 28],'Callback',@onRecord);
    h.btnPick = uicontrol(h.fig,'Style','pushbutton','String','Pick WAV & Verify',...
        'Position',[340 20 160 28],'Callback',@onPick);

    % ---- Callbacks ----
    function onRecord(~,~)
        claim = getClaim();
        setStatus('Recording...', 'info');

        FS = 48000; secs = 1.0;
        try
            dev = audiodevinfo;
        catch
            dev.input = [];
        end

        if isempty(dev) || isempty(dev.input)
            setStatus('No mic found. Using prerecorded file.', 'warn');
            f = findOneFileFor(claim);
            if f == ""
                setStatus("No files for user "+claim, 'err'); return;
            end
            [x,fs] = audioread(f);
            safePlot(h.ax,x,fs);
            doVerify(f, claim);
            return;
        end

        try
            recObj = audiorecorder(FS,16,1);
            recordblocking(recObj, secs);
            x = getaudiodata(recObj);
            x = postproc(x);
            safePlot(h.ax,x,FS);

            outDir = fullfile(PROJECT_ROOT,'outputs','runtime');
            if ~isfolder(outDir), mkdir(outDir); end
            fp = fullfile(outDir, sprintf('trial_%s_%s.wav', claim, datestr(now,'HHMMSS')));
            audiowrite(fp, x, FS);
            doVerify(fp, claim);
        catch ME
            setStatus("Record error: "+ME.message, 'err');
        end
    end

    function onPick(~,~)
        claim = getClaim();
        [fn,fp] = uigetfile({'*.wav','WAV Files (*.wav)'}, 'Pick WAV');
        if isequal(fn,0), return; end
        f = fullfile(fp,fn);
        try
            [x,fs] = audioread(f);
            safePlot(h.ax,x,fs);
            doVerify(f, claim);
        catch ME
            setStatus("Verify error: "+ME.message, 'err');
        end
    end

    % ---- Helpers ----
    function claim = getClaim()
        vals = get(h.dd,'String');
        idx  = get(h.dd,'Value');
        claim = string(vals{idx});
    end

    function setStatus(msg, kind)
        switch lower(kind)
            case 'ok',   col = [0 0.55 0];
            case 'warn', col = [0.85 0.4 0];
            case 'err',  col = [0.8 0 0];
            otherwise,   col = [0 0 0];
        end
        set(h.status,'String',char(msg),'ForegroundColor',col);
        drawnow;
    end

    function f = findOneFileFor(claim)
        S2 = dir(fullfile(AUDIO_MNIST_ROOT,'**',sprintf('*_%s_*.wav',claim)));
        if isempty(S2), f = ""; else, f = fullfile(S2(1).folder,S2(1).name); end
    end

    function x = postproc(x)
        if size(x,2)>1, x = mean(x,2); end
        x = x(:);
        if any(x)
            x = x - mean(x);
            x = x ./ max(1e-9, max(abs(x)));
        end
    end

    function safePlot(ax,x,fs)
        try
            if size(x,2)>1, x = mean(x,2); end
            x = x(:);
            N = numel(x); maxPts = 5000;
            if N > maxPts
                idx = round(linspace(1,N,maxPts));
                xp = x(idx); tp = (idx-1)/fs;
            else
                tp = (0:N-1)/fs; xp = x;
            end
            plot(ax,tp,xp,'b-'); grid(ax,'on');
            xlabel(ax,'Time (s)'); ylabel(ax,'Amplitude');
            drawnow limitrate;
        catch ME
            if contains(lower(ME.message),'operation terminated by user')
                % ignore
            else
                rethrow(ME);
            end
        end
    end

    function doVerify(f, claim)
        try
            res = verify_user_minimal(f, claim);
            if res.accept
                title(h.ax, sprintf('Claim=%s | Pred=%s | ✅ ACCEPTED', res.claimedUser, res.predictedUser), 'Color',[0 0.55 0]);
                setStatus("ACCESS GRANTED", 'ok');
            else
                title(h.ax, sprintf('Claim=%s | Pred=%s | 🔐 DENIED', res.claimedUser, res.predictedUser), 'Color',[0.8 0 0]);
                setStatus("ACCESS DENIED", 'warn');
            end
        catch ME
            setStatus("Verify error: "+ME.message, 'err');
        end
    end
end
