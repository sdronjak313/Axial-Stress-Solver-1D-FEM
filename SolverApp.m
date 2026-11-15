function SolverApp()
    bgColor    = [0.12 0.12 0.12];
    panelColor = [0.18 0.18 0.18];
    textColor  = [0.9 0.9 0.9];
    axisColor  = [0.15 0.15 0.15];
    fieldColor = [0.25 0.25 0.25];

    sigmaCh = char(963);  alphaCh = char(945);  deltaCh = char(916);  degCh = char(176);

    fig = uifigure('Name', 'Axial Stress Solver', ...
                   'Position', [30, 30, 1350, 950], 'Color', bgColor);

    uilabel(fig, 'Position', [20, 900, 1310, 40], ...
        'Text', 'AXIAL STRESS SOLVER', ...
        'FontSize', 22, 'FontWeight', 'bold', 'FontColor', [0.2, 0.8, 0.4], ...
        'HorizontalAlignment', 'center');

    pnlInput = uipanel(fig, 'Position', [20, 440, 320, 450], ...
        'BackgroundColor', panelColor, 'ForegroundColor', textColor, ...
        'Title', ' 1. Pre-Processing (Geometry, Forces, Thermal)', 'FontSize', 12, 'FontWeight', 'bold');

    uilabel(pnlInput, 'Position', [15, 385, 290, 20], 'Text', 'Segment Lengths L (mm):', 'FontColor', textColor);
    inputL = uieditfield(pnlInput, 'text', 'Position', [15, 361, 290, 24], ...
        'Value', '200, 150, 100', 'BackgroundColor', fieldColor, 'FontColor', textColor);

    uilabel(pnlInput, 'Position', [15, 335, 290, 20], 'Text', 'Segment Diameters D (mm):', 'FontColor', textColor);
    inputD = uieditfield(pnlInput, 'text', 'Position', [15, 311, 290, 24], ...
        'Value', '40, 20, 30', 'BackgroundColor', fieldColor, 'FontColor', textColor);

    uilabel(pnlInput, 'Position', [15, 285, 290, 20], 'Text', 'Elastic Modulus E (GPa):', 'FontColor', textColor);
    inputE = uieditfield(pnlInput, 'text', 'Position', [15, 261, 290, 24], ...
        'Value', '210', 'BackgroundColor', fieldColor, 'FontColor', textColor);

    chkThermal = uicheckbox(pnlInput, 'Position', [15, 233, 290, 22], ...
        'Text', 'Include thermal load (heating / cooling)', ...
        'FontColor', [1 0.65 0.2], 'Value', false);

    uilabel(pnlInput, 'Position', [15, 205, 290, 20], ...
        'Text', ['Global ' alphaCh ' (x10^-6 / ' degCh 'C):'], 'FontColor', [1 0.65 0.2]);
    inputAlpha = uieditfield(pnlInput, 'numeric', 'Position', [15, 181, 290, 24], ...
        'Value', 12, 'BackgroundColor', fieldColor, 'FontColor', textColor, 'Enable', 'off');

    uilabel(pnlInput, 'Position', [15, 155, 290, 20], ...
        'Text', ['Global ' deltaCh 'T (' degCh 'C):  + heat, - cool'], 'FontColor', [1 0.65 0.2]);
    inputDT = uieditfield(pnlInput, 'numeric', 'Position', [15, 131, 290, 24], ...
        'Value', 40, 'BackgroundColor', fieldColor, 'FontColor', textColor, 'Enable', 'off');

    uilabel(pnlInput, 'Position', [15, 105, 290, 20], 'Text', 'External Forces (kN) - Positive to the right:', 'FontColor', [1, 0.4, 0.4]);
    inputForce = uieditfield(pnlInput, 'text', 'Position', [15, 81, 290, 24], ...
        'Value', '50, -20', 'BackgroundColor', fieldColor, 'FontColor', textColor);

    uilabel(pnlInput, 'Position', [15, 55, 290, 20], 'Text', 'Force Positions X (mm) from left wall:', 'FontColor', [1, 0.4, 0.4]);
    inputForcePos = uieditfield(pnlInput, 'text', 'Position', [15, 31, 290, 24], ...
        'Value', '200, 350', 'BackgroundColor', fieldColor, 'FontColor', textColor);

    chkThermal.ValueChangedFcn = @(src, ~) ToggleThermal(src.Value, inputAlpha, inputDT);

    btnPreview = uibutton(fig, 'push', 'Position', [20, 385, 320, 45], ...
        'Text', '2. GENERATE 3D MODEL & INPUT FILE', 'FontSize', 13, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.8, 0.5, 0], 'FontColor', [1 1 1], ...
        'ButtonPushedFcn', @(~, ~) DrawPreview3D(fig));

    btnSolver = uibutton(fig, 'push', 'Position', [20, 330, 320, 45], ...
        'Text', '3. RUN C SOLVER & LOAD RESULTS', 'FontSize', 13, 'FontWeight', 'bold', ...
        'BackgroundColor', [0, 0.45, 0.74], 'FontColor', [1 1 1], 'Enable', 'off', ...
        'ButtonPushedFcn', @(~, ~) RunCSolver(fig));

    pnlResults = uipanel(fig, 'Position', [20, 20, 320, 300], ...
        'BackgroundColor', [0.1 0.1 0.12], 'ForegroundColor', [0 0.8 1], ...
        'Title', ' 4. Post-Processing (Results)', 'FontSize', 13, 'FontWeight', 'bold');

    uilabel(pnlResults, 'Position', [10, 230, 300, 22], 'Text', 'Left Wall Reaction (R_A):', 'FontColor', textColor);
    lblRA = uilabel(pnlResults, 'Position', [10, 200, 300, 30], 'Text', '- kN', 'FontColor', [1 0.7 0], 'FontSize', 18, 'FontWeight', 'bold');

    uilabel(pnlResults, 'Position', [10, 170, 300, 22], 'Text', 'Right Wall Reaction (R_B):', 'FontColor', textColor);
    lblRB = uilabel(pnlResults, 'Position', [10, 140, 300, 30], 'Text', '- kN', 'FontColor', [1 0.7 0], 'FontSize', 18, 'FontWeight', 'bold');

    uilabel(pnlResults, 'Position', [10, 110, 300, 22], 'Text', 'Max Normal Stress (signed):', 'FontColor', textColor);
    lblSigMax = uilabel(pnlResults, 'Position', [10, 80, 300, 30], 'Text', '- MPa', 'FontColor', [1 0.2 0.2], 'FontSize', 18, 'FontWeight', 'bold');

    uilabel(pnlResults, 'Position', [10, 50, 300, 22], 'Text', 'Max Displacement:', 'FontColor', textColor);
    lblUMax = uilabel(pnlResults, 'Position', [10, 20, 300, 30], 'Text', '- mm', 'FontColor', [0 0.8 0.4], 'FontSize', 18, 'FontWeight', 'bold');

    pnlView = uipanel(fig, 'Position', [1230, 650, 95, 240], ...
        'BackgroundColor', panelColor, 'Title', 'Camera', 'ForegroundColor', textColor);

    uibutton(pnlView, 'push', 'Position', [10, 180, 75, 30], 'Text', 'Isometric', 'ButtonPushedFcn', @(~,~) SetView(fig, 3));
    uibutton(pnlView, 'push', 'Position', [10, 140, 75, 30], 'Text', 'Front', 'ButtonPushedFcn', @(~,~) SetView(fig, [0, 0]));
    uibutton(pnlView, 'push', 'Position', [10, 100, 75, 30], 'Text', 'Top', 'ButtonPushedFcn', @(~,~) SetView(fig, [0, 90]));
    uibutton(pnlView, 'push', 'Position', [10, 50, 75, 40], 'Text', 'Wireframe', 'ButtonPushedFcn', @(~,~) ToggleWireframe(fig));

    axPreview = uiaxes(fig, 'Position', [360, 650, 860, 240], 'Color', axisColor, ...
        'XColor', textColor, 'YColor', textColor, 'ZColor', textColor, 'GridColor', textColor);
    title(axPreview, 'Pre-processing: Geometry, Forces & Thermal Load', 'Color', [0.8 0.8 0.8]);
    ProtectAxis(axPreview, true);

    axStressView = uiaxes(fig, 'Position', [360, 390, 860, 240], 'Color', axisColor, ...
        'XColor', textColor, 'YColor', textColor, 'ZColor', textColor, 'GridColor', textColor);
    title(axStressView, 'Post-processing: Stress Distribution & Deformation', 'Color', [0.8 0.8 0.8]);
    ProtectAxis(axStressView, true);

    graphHeight = 115;
    axDisp = uiaxes(fig, 'Position', [360, 20+graphHeight*2, 960, graphHeight], 'Color', axisColor, 'XColor', textColor, 'YColor', textColor, 'GridColor', textColor);
    title(axDisp, 'Displacement Diagram u (mm)', 'Color', textColor); ProtectAxis(axDisp, false);

    axForce = uiaxes(fig, 'Position', [360, 20+graphHeight, 960, graphHeight], 'Color', axisColor, 'XColor', textColor, 'YColor', textColor, 'GridColor', textColor);
    title(axForce, 'Axial Force Diagram N (kN)', 'Color', textColor); ProtectAxis(axForce, false);

    axStress = uiaxes(fig, 'Position', [360, 20, 960, graphHeight], 'Color', axisColor, 'XColor', textColor, 'YColor', textColor, 'GridColor', textColor);
    title(axStress, ['Normal Stress Diagram ' sigmaCh ' (MPa)'], 'Color', textColor); ProtectAxis(axStress, false);

    inputs = struct('L', inputL, 'D', inputD, 'E', inputE, 'chkThermal', chkThermal, ...
                    'Alpha', inputAlpha, 'DT', inputDT, 'Force', inputForce, 'ForcePos', inputForcePos);

    fig.UserData = struct('axPreview', axPreview, 'axStressView', axStressView, ...
                          'axDisp', axDisp, 'axForce', axForce, 'axStress', axStress, ...
                          'btnSolver', btnSolver, 'lblRA', lblRA, 'lblRB', lblRB, ...
                          'lblSigMax', lblSigMax, 'lblUMax', lblUMax, ...
                          'in', inputs, 'maxD', 0, 'L_tot', 0, 'isWireframe', false, ...
                          'arrL', [], 'arrD', [], 'res', []);

    uilabel(fig, 'Position', [1150, 5, 180, 22], 'Text', '@author Stefan Dronjak', ...
        'FontSize', 11, 'FontAngle', 'italic', 'FontColor', [0.5 0.5 0.5], 'HorizontalAlignment', 'right');
end

function ProtectAxis(ax, is3D)
ax.Toolbar.Visible = 'off';
if is3D
    ax.Interactions = [rotateInteraction, zoomInteraction];
else
    ax.Interactions = []; 
    ax.NextPlot = 'replacechildren';   
end
end

function ToggleThermal(isOn, fieldAlpha, fieldDT)
    state = 'off';
    if isOn, state = 'on'; end
    fieldAlpha.Enable = state;
    fieldDT.Enable = state;
end

function v = ParseVector(s)
    s = strrep(char(s), ',', ' ');
    v = sscanf(s, '%f')';
    if isempty(v), v = zeros(1, 0); end
end

function SetView(fig, angle)
    view(fig.UserData.axPreview, angle);
    view(fig.UserData.axStressView, angle);
end

function ToggleWireframe(fig)
    data = fig.UserData;
    bars = findobj(data.axPreview, 'Tag', 'bar');
    if data.isWireframe
        set(bars, 'FaceAlpha', 1, 'EdgeColor', 'none'); data.isWireframe = false;
    else
        set(bars, 'FaceAlpha', 0.1, 'EdgeColor', [0.6 0.6 0.6]); data.isWireframe = true;
    end
    fig.UserData = data;
end

function r = RadiusAt(L, D, x)
    edges = [0 cumsum(L)];
    r = 0;
    for i = 1:numel(L)
        if x >= edges(i) - 1e-6 && x <= edges(i+1) + 1e-6
            r = max(r, D(i) / 2);
        end
    end
    if r == 0, r = max(D) / 2; end
end

function DrawBarElement(ax, x1, x2, r, col, useCData)
    n = 48;
    th = linspace(0, 2*pi, n);
    Y = r * cos(th);  Z = r * sin(th);
    X2 = [x1 * ones(1, n); x2 * ones(1, n)];
    Y2 = [Y; Y];  Z2 = [Z; Z];
    common = {'EdgeColor', 'none', 'AmbientStrength', 0.8, 'DiffuseStrength', 0.5, ...
              'SpecularStrength', 0.05, 'Tag', 'bar'};
    if useCData
        surf(ax, X2, Y2, Z2, col * ones(2, n), 'FaceColor', 'flat', 'FaceLighting', 'gouraud', common{:});
        for xc = [x1 x2]
            patch(ax, 'XData', xc * ones(1, n), 'YData', Y, 'ZData', Z, 'CData', col, ...
                  'FaceColor', 'flat', 'FaceLighting', 'flat', common{:});
        end
    else
        surf(ax, X2, Y2, Z2, 'FaceColor', col, 'FaceAlpha', 1, 'FaceLighting', 'gouraud', common{:});
        for xc = [x1 x2]
            patch(ax, 'XData', xc * ones(1, n), 'YData', Y, 'ZData', Z, ...
                  'FaceColor', col, 'FaceAlpha', 1, 'FaceLighting', 'flat', common{:});
        end
    end
end

function DrawWalls(ax, L_tot, maxD)
    W = maxD * 1.2;
    [Yw, Zw] = meshgrid([-W W], [-W W]);
    surf(ax, zeros(2,2), Yw, Zw, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', [0.55 0.55 0.55], 'Tag', 'wall');
    surf(ax, ones(2,2) * L_tot, Yw, Zw, 'FaceColor', [0.3 0.3 0.3], 'EdgeColor', [0.55 0.55 0.55], 'Tag', 'wall');
end

function PlotDiagram(ax, x, y, col, isDisp)
cla(ax);
if nargin < 5, isDisp = false; end
if isempty(x) || isempty(y), return; end 

ax.NextPlot = 'add';

x_plot = [x(1), x, x(end)];
y_plot = [0, y, 0];

fill(ax, x_plot, y_plot, col, 'FaceAlpha', 0.15, 'EdgeColor', 'none');

plot(ax, [min(x) max(x)], [0 0], '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);

plot(ax, x_plot, y_plot, '-', 'Color', col, 'LineWidth', 2.5);

if isDisp
    nodes_x = [x(1:2:end), x(end)];
    nodes_y = [y(1:2:end), y(end)];
    for i = 1:length(nodes_x)
        if abs(nodes_y(i)) > 1e-6
            vAlign = 'bottom'; if nodes_y(i) < 0, vAlign = 'top'; end
            text(ax, nodes_x(i), nodes_y(i), sprintf('%.4f', nodes_y(i)), ...
                'Color', col, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', vAlign, 'FontWeight', 'bold');
        end
    end
else
    for i = 1:2:length(x)
        val = y(i);
        if abs(val) > 1e-6
            x_mid = (x(i) + x(i+1)) / 2;
            vAlign = 'bottom'; if val < 0, vAlign = 'top'; end
            text(ax, x_mid, val, sprintf('%.2f', val), ...
                'Color', col, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', vAlign, 'FontWeight', 'bold');
        end
    end
end

ax.NextPlot = 'replacechildren';
grid(ax, 'on');
xlim(ax, [min(x) max(x)]);

ymin = min(y_plot);
ymax = max(y_plot);
span = ymax - ymin;
if span < 1e-6, span = 1; end
ylim(ax, [ymin - 0.25*span, ymax + 0.3*span]);
end

function gapZ = VerticalGap(L_tot, maxD)
    gapZ = max(maxD * 0.5, L_tot * 0.03);
end

function DrawForceArrows(ax, Forces, ForcePos, L, D)
    n = numel(Forces);
    if n == 0, return; end
    L_tot = sum(L);  maxD = max(D);
    arrowLen  = L_tot * 0.10;
    labelHalf = L_tot * 0.07;
    gap       = L_tot * 0.01;
    red = [1 0.2 0.2];

    xTail = zeros(1, n);  lo = zeros(1, n);  hi = zeros(1, n);  center = zeros(1, n);
    for i = 1:n
        if Forces(i) >= 0, xTail(i) = ForcePos(i) - arrowLen;
        else,              xTail(i) = ForcePos(i) + arrowLen; end
        center(i) = (xTail(i) + ForcePos(i)) / 2;
        lo(i) = min([xTail(i), ForcePos(i), center(i) - labelHalf]);
        hi(i) = max([xTail(i), ForcePos(i), center(i) + labelHalf]);
    end

    [~, order] = sort(lo);
    laneEnd = [];  lane = zeros(1, n);
    for k = order
        placed = false;
        for m = 1:numel(laneEnd)
            if lo(k) > laneEnd(m) + gap
                lane(k) = m;  laneEnd(m) = hi(k);  placed = true;  break;
            end
        end
        if ~placed
            laneEnd(end+1) = hi(k); 
            lane(k) = numel(laneEnd);
        end
    end

    laneGap = max(maxD * 0.6, L_tot * 0.05);
    for i = 1:n
        z = maxD / 2 + laneGap * 0.6 + (lane(i) - 1) * laneGap;
        y = (lane(i) - 1) * laneGap * 0.8;
        rAt = RadiusAt(L, D, ForcePos(i));

        quiver3(ax, xTail(i), y, z, ForcePos(i) - xTail(i), 0, 0, 0, ...
            'Color', red, 'LineWidth', 3, 'MaxHeadSize', 1.0);
        plot3(ax, [ForcePos(i) ForcePos(i)], [y 0], [z rAt], ':', 'Color', red, 'LineWidth', 1.2);
        plot3(ax, ForcePos(i), 0, rAt, 'o', 'MarkerSize', 6, ...
            'MarkerFaceColor', red, 'MarkerEdgeColor', [1 1 1]);
        text(ax, center(i), y, z + laneGap * 0.35, sprintf('%.1f kN', abs(Forces(i))), ...
            'Color', red, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
end

function DrawThermalLabels(ax, L_tot, maxD, dT)
    if dT == 0, return; end
    gapZ = VerticalGap(L_tot, maxD);
    zT = -(maxD / 2 + 3.2 * gapZ);
    
    if dT > 0, col = [1 0.55 0.2]; else, col = [0.4 0.75 1]; end
    plot3(ax, [0 L_tot], [0 0], [zT zT], '-', 'Color', col, 'LineWidth', 2);
    text(ax, L_tot / 2, 0, zT - gapZ * 0.6, ...
        sprintf('\\Delta T = %+g %sC', dT, char(176)), ...
        'Color', col, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
end

function DrawReactions(fig, RA, RB)
    data = fig.UserData;  ax = data.axPreview;
    delete(findobj(ax, 'Tag', 'reaction'));
    L_tot = data.L_tot;  maxD = data.maxD;
    gapZ = VerticalGap(L_tot, maxD);
    arrowLen = L_tot * 0.10;
    z = -(maxD / 2 + gapZ);
    vals = [RA RB];  xs = [0 L_tot];  names = {'R_A', 'R_B'};
    orange = [1 0.7 0];
    hold(ax, 'on');
    for k = 1:2
        dirn = sign(vals(k));  if dirn == 0, dirn = 1; end
        xTail = xs(k) - dirn * arrowLen;
        quiver3(ax, xTail, 0, z, dirn * arrowLen, 0, 0, 0, 'Color', orange, ...
            'LineWidth', 3, 'MaxHeadSize', 1.0, 'Tag', 'reaction');
        plot3(ax, [xs(k) xs(k)], [0 0], [z 0], ':', 'Color', orange, 'LineWidth', 1.2, 'Tag', 'reaction');
        text(ax, xTail + dirn * arrowLen / 2, 0, z - gapZ * 0.8, ...
            sprintf('%s = %.2f kN', names{k}, abs(vals(k))), 'Color', orange, ...
            'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Tag', 'reaction');
    end
    hold(ax, 'off');
end

function DrawPreview3D(fig)
    data = fig.UserData;
    in = data.in;

    L = ParseVector(in.L.Value);
    D = ParseVector(in.D.Value);
    E = ParseVector(in.E.Value);
    Forces = ParseVector(in.Force.Value);
    ForcePos = ParseVector(in.ForcePos.Value);
    nSeg = numel(L);

    useThermal = in.chkThermal.Value;
    if useThermal
        alphaVal = in.Alpha.Value * 1e-6;     
        dT = in.DT.Value;
    else
        alphaVal = 0.0;
        dT = 0.0;
    end

    err = '';
    if nSeg == 0 || any(L <= 0)
        err = 'Segment lengths must be positive numbers.';
    elseif numel(D) ~= nSeg || any(D <= 0)
        err = 'Provide one positive diameter per segment.';
    elseif numel(E) ~= 1 || E <= 0
        err = 'Provide exactly one positive elastic modulus for the entire bar.';
    elseif numel(Forces) ~= numel(ForcePos)
        err = 'The number of forces must match the number of force positions.';
    elseif any(ForcePos < 0) || any(ForcePos > sum(L))
        err = 'Force positions must lie between 0 and the total bar length.';
    end
    
    if ~isempty(err)
        uialert(fig, err, 'Input Error', 'Icon', 'error');
        return;
    end

    filePath = fullfile(pwd, 'ulaz_za_C.txt');
    fid = fopen(filePath, 'w');
    if fid == -1
        uialert(fig, 'Error creating input file!', 'Error', 'Icon', 'error');
        return;
    end
    fprintf(fid, '%d\n', nSeg);
    fprintf(fid, '%.10g ', L);        fprintf(fid, '\n');
    fprintf(fid, '%.10g ', D);        fprintf(fid, '\n');
    fprintf(fid, '%.10g ', E);        fprintf(fid, '\n');
    fprintf(fid, '%.10g %.10g\n', alphaVal, dT); 
    fprintf(fid, '%d\n', numel(Forces));
    fprintf(fid, '%.10g ', Forces);   fprintf(fid, '\n');
    fprintf(fid, '%.10g ', ForcePos); fprintf(fid, '\n');
    fclose(fid);

    L_tot = sum(L);  maxD = max(D);
    data.L_tot = L_tot;  data.maxD = maxD;
    data.arrL = L;  data.arrD = D;  data.res = [];

    ax = data.axPreview;
    cla(ax);  delete(findobj(ax, 'Type', 'light'));
    hold(ax, 'on');

    barColor = [0.80 0.81 0.83];
    x0 = 0;
    for i = 1:nSeg
        DrawBarElement(ax, x0, x0 + L(i), D(i) / 2, barColor, false);
        x0 = x0 + L(i);
    end
    DrawWalls(ax, L_tot, maxD);
    DrawForceArrows(ax, Forces, ForcePos, L, D);
    if useThermal, DrawThermalLabels(ax, L_tot, maxD, dT); end

    view(ax, 3);  axis(ax, 'equal');  grid(ax, 'on');
    camlight(ax, 'headlight');
    hold(ax, 'off');

    cla(data.axStressView);  colorbar(data.axStressView, 'off');
    cla(data.axDisp);  cla(data.axForce);  cla(data.axStress);
    data.lblRA.Text = '- kN';  data.lblRB.Text = '- kN';
    data.lblSigMax.Text = '- MPa';  data.lblUMax.Text = '- mm';

    data.btnSolver.Enable = 'on';
    data.isWireframe = false;
    fig.UserData = data;

    msg = sprintf('Geometry loaded and file exported to:\n%s\n\nReady for C calculation!', filePath);
    uialert(fig, msg, 'Pre-Processing Complete', 'Icon', 'success');
end

function RunCSolver(fig)
    data = fig.UserData;

    outputPath = fullfile(pwd, 'rezultati_iz_C.txt');
    if isfile(outputPath), delete(outputPath); end

    if ispc, cmd = 'solver.exe'; else, cmd = './solver.exe'; end
    [status, cmdout] = system(cmd);
    if status ~= 0
        uialert(fig, sprintf('Solver reported an error:\n%s', strtrim(cmdout)), ...
            'Solver Error', 'Icon', 'error');
        return;
    end

    fid_in = fopen(outputPath, 'r');
    if fid_in == -1
        uialert(fig, 'C program did not create the results file. Check that solver.exe is compiled from the latest math.c.', ...
            'Solver Error', 'Icon', 'error');
        return;
    end

    reactions = fscanf(fid_in, '%f', 2);
    n_nodes = fscanf(fid_in, '%d', 1);
    X_nodes = fscanf(fid_in, '%f', n_nodes); 
    U_nodes = fscanf(fid_in, '%f', n_nodes); 

    n_plot = fscanf(fid_in, '%d', 1);
    X_2D     = fscanf(fid_in, '%f', n_plot)';
    Disp_2D  = fscanf(fid_in, '%f', n_plot)';
    Stress_2D = fscanf(fid_in, '%f', n_plot)';
    Force_2D = fscanf(fid_in, '%f', n_plot)';
    fclose(fid_in);

    Reaction_A = reactions(1);
    Reaction_B = reactions(2);

    res.xl = X_2D(1:2:end);      res.xr = X_2D(2:2:end);
    res.ul = Disp_2D(1:2:end);   res.ur = Disp_2D(2:2:end);
    res.sigma = Stress_2D(1:2:end);
    res.N = Force_2D(1:2:end);
    data.res = res;
    fig.UserData = data;

    data.lblRA.Text = sprintf('%.2f kN (%s)', abs(Reaction_A), GetDirection(Reaction_A));
    data.lblRB.Text = sprintf('%.2f kN (%s)', abs(Reaction_B), GetDirection(Reaction_B));
    [~, idx] = max(abs(Stress_2D));
    data.lblSigMax.Text = sprintf('%.2f MPa', Stress_2D(idx));
    data.lblUMax.Text = sprintf('%.4f mm', max(abs(Disp_2D)));

    DrawReactions(fig, Reaction_A, Reaction_B);
    DrawStressView(fig);

    PlotDiagram(data.axDisp,   X_2D, Disp_2D,   [0 0.8 0.4], true);
    PlotDiagram(data.axForce,  X_2D, Force_2D,  [0 0.6 1], false);
    PlotDiagram(data.axStress, X_2D, Stress_2D, [1 0.2 0.2], false);
end

function DrawStressView(fig)
    data = fig.UserData;
    if isempty(data.res) || isempty(data.res.sigma), return; end 
    res = data.res;
    ax = data.axStressView;
    L = data.arrL;  D = data.arrD;  L_tot = data.L_tot;  maxD = data.maxD;
    edges = cumsum(L);
    nEl = numel(res.sigma);

    cVal = res.sigma;                      
    cbLabel = ['Axial Stress ' char(963) ' (MPa)'];

    uMax = max(abs([res.ul res.ur]));
    if uMax > 0
        raw = 0.06 * L_tot / uMax;
        mag = 10^floor(log10(raw));
        m = raw / mag;
        if m >= 5, nice = 5; elseif m >= 2, nice = 2; else, nice = 1; end
        defScale = max(nice * mag, 1);
    else
        defScale = 1;
    end

    cla(ax);  delete(findobj(ax, 'Type', 'light'));
    hold(ax, 'on');

    x0 = 0;
    for i = 1:numel(L)
        r = D(i) / 2;  x1 = x0 + L(i);
        plot3(ax, [x0 x1 x1 x0 x0], zeros(1,5), [r r -r -r r], ':', 'Color', [0.6 0.6 0.6]);
        plot3(ax, [x0 x1 x1 x0 x0], [r r -r -r r], zeros(1,5), ':', 'Color', [0.6 0.6 0.6]);
        x0 = x1;
    end

    for e = 1:nEl
        xm = (res.xl(e) + res.xr(e)) / 2;
        s = find(xm <= edges + 1e-5, 1);
        if isempty(s), s = numel(L); end
        DrawBarElement(ax, res.xl(e) + res.ul(e) * defScale, ...
                           res.xr(e) + res.ur(e) * defScale, D(s) / 2, cVal(e), true);
    end
    
    DrawWalls(ax, L_tot, maxD);

    cmax = max(abs(cVal));
    if cmax < 1e-9, cmax = 1; end
    cmin = -cmax;

    colormap(ax, 'jet');
    ax.CLim = [cmin cmax];
    
    cb = colorbar(ax);
    cb.Color = [0.9 0.9 0.9];
    cb.Label.String = cbLabel;

    text(ax, L_tot / 2, 0, maxD * 1.3, sprintf('Deformation scale: x%g', defScale), ...
        'Color', [0.9 0.9 0.9], 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    view(ax, 3);  axis(ax, 'equal');  grid(ax, 'on');
    camlight(ax, 'headlight');
    hold(ax, 'off');
end

function str = GetDirection(val)
    if val > 0
        str = ['Right ' char(8594)];
    else
        str = [char(8592) ' Left'];
    end
end