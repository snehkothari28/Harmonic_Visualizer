%Created by Sneh Kothari
%https://github.com/snehkothari28/Harmonic_Visualizer
%This is a program to visualise the effect of harmonic's magnitude and its
%phase on the waveform, IHD and THD.
    
classdef thd_ihd_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        LockPlotSwitch                 matlab.ui.control.Switch
        LockPlotSwitchLabel            matlab.ui.control.Label
        waves                          matlab.ui.control.Switch
        ShowallwavesLabel              matlab.ui.control.Label
        THDandIHDSignificanceVisualiserbySnehKothariLabel  matlab.ui.control.Label
        TotalHarmonicDistortionEditField  matlab.ui.control.NumericEditField
        ControlPanel                   matlab.ui.container.Panel
        TotalHarmonicDistortionLabel   matlab.ui.control.Label
        NumberofHarmoniccontentsLabel  matlab.ui.control.Label
        NumberofHarmoniccontent        matlab.ui.control.NumericEditField
        UIAxes                         matlab.ui.control.UIAxes
    end

    properties (Access = private)
        time % time vector
        mag %magntiude of all harmonics
        phase % phase of all harmonics

        %Control panel to maniuplate the values of harmonics
        GridLayout         matlab.ui.container.GridLayout

        %Below shown values control the elements of control panel
        txtarea
        slidermag
        sliderph
        label
        swtch
        
        %lock the plot output
        update_plot
        limits
    end

    methods (Access = private)
        %This function updates the plot after each change
        function update(app)
            color = [0,0,0];
            if app.waves.Value
                color = jet(app.NumberofHarmoniccontent.Value + 1);
            end
            total = zeros(size(app.time));
            for i = 1:app.NumberofHarmoniccontent.Value

                txtareacreate(app,i);
                if app.waves.Value
                    plot(app.UIAxes,app.time,app.mag(i)* ...
                        sin(2*pi*50*i*app.time+app.phase(i)), ...
                        "Color",color(i,:), "DisplayName", "Harmonic "+ i);
                    hold(app.UIAxes,"on");
                end
                total = total + app.mag(i)* ...
                    sin(2*pi*50*i*app.time+app.phase(i));
            end
            app.TotalHarmonicDistortionEditField.Value = ...
                100*sqrt(sum(app.mag(2:app.NumberofHarmoniccontent.Value) ...
                .^2))/app.mag(1);
            plot(app.UIAxes,app.time,total,"Color",color(end,:), ...
                "DisplayName", "Resultant Wave");
            legend(app.UIAxes)
            hold(app.UIAxes,"off")
            if (app.update_plot + app.LockPlotSwitch.Value) > 0
                app.UIAxes.YLim = app.limits * [-1 1];
            else
                app.limits = max(total)*1.1;
                app.UIAxes.YLim = app.limits * [-1 1];
            end
            
        end

        %This function creates the dynamic control panel
        function createobj(app)
            app.GridLayout = uigridlayout(app.ControlPanel);
            app.GridLayout.ColumnWidth = {'1.5x', '2.5x', '5x', '1.5x'};
            app.GridLayout.RowHeight = num2cell(repmat([27, 54], ...
                1,app.NumberofHarmoniccontent.Value));
            app.GridLayout.ColumnSpacing = 4.6;
            app.GridLayout.RowSpacing = 6.1;
            app.GridLayout.Padding = [4.6 6.1 4.6 6.1];
            app.GridLayout.Scrollable = 'on';

            if app.NumberofHarmoniccontent.Value > size(app.mag,2)
                app.mag = [app.mag, zeros(1,app.NumberofHarmoniccontent.Value-size(app.mag,2))];
                app.phase = [app.phase, zeros(1,app.NumberofHarmoniccontent.Value-size(app.phase,2))];
            end

            for i = 1:app.NumberofHarmoniccontent.Value
                % Create TextArea
                app.txtarea{i} = uitextarea(app.GridLayout);
                app.txtarea{i}.Editable = 'off';
                app.txtarea{i}.Layout.Row = [1 2] + 2*(i-1);
                app.txtarea{i}.Layout.Column = 4;

                % Create Switch
                app.swtch{i} = uiswitch(app.GridLayout, 'slider');
                app.swtch{i}.ValueChangedFcn = {@app.swtchfcn, i};
                app.swtch{i}.Items = {'Magnitude', 'Phase'};
                app.swtch{i}.Layout.Row = 2*i;
                app.swtch{i}.Layout.Column = 2;
                app.swtch{i}.Value = 'Magnitude';


                % Create Harmonic Label
                app.label{i} = uilabel(app.GridLayout);
                app.label{i}.Layout.Row = 2*i - 1;
                app.label{i}.Layout.Column = 1;
                app.label{i}.Text = sprintf('Harmonic %d:',i);

                % Create Harmonic magnitude Slider
                app.slidermag{i}= uislider(app.GridLayout);
                app.slidermag{i}.ValueChangingFcn = {@app.slidermagfcn, i};
                app.slidermag{i}.ValueChangedFcn = @app.slidermagValChangedfcn;
                app.slidermag{i}.Layout.Row = [1 2] + 2*(i-1);
                app.slidermag{i}.Layout.Column = 3;
                app.slidermag{i}.Value = app.mag(i);

                % Create Harmonic phase Slider
                app.sliderph{i}= uislider(app.GridLayout);
                app.sliderph{i}.ValueChangingFcn = {@app.sliderphfcn, i};
                app.slidermag{i}.ValueChangedFcn = @app.sliderValChangedfcn;
                app.sliderph{i}.Layout.Row = [1 2] + 2*(i-1);
                app.sliderph{i}.Layout.Column = 3;
                app.sliderph{i}.Limits = [0 360];
                app.sliderph{i}.Value = app.phase(i);
                app.sliderph{i}.Visible = 'off';
            end
            update(app);
        end

        %This app creates modifies the text shown after each harmonic
        function txtareacreate(app,i)
            txt{1} = sprintf('Order:%d',i);
            txt{2} = sprintf('Mag: %0.2f',app.mag(i));
            txt{3} = sprintf('Phase: %0.2f',app.phase(i));
            txt{4} = sprintf('IHD: %0.2f %%',app.mag(i)/app.mag(1)*100);
            app.txtarea{i}.Value = txt;
        end

        %This app creates decides to show either magnitude slider or phase
        %slider
        function swtchfcn(app,~,~,i)
            if strcmp(app.swtch{i}.Value,'Magnitude')
                app.sliderph{i}.Visible = 'off';
                app.slidermag{i}.Visible = 'on';
            else
                app.sliderph{i}.Visible = 'on';
                app.slidermag{i}.Visible = 'off';
            end
        end

        %This function assign the slider value to appropriate magnitude
        function slidermagfcn(app,~,event,i)
            app.update_plot = 1;
            app.mag(i) = event.Value;
            update(app);
        end

        %This function assign the slider value to appropriate phase
        function sliderphfcn(app,~,event,i)
            app.update_plot = 1;
            app.phase(i) = event.Value;
            update(app);
        end
        function sliderValChangedfcn(app,~,~)
            app.update_plot = 0;
            update(app);
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clc;
            app.time = linspace(0,1/50,1000);
            app.NumberofHarmoniccontent.Value = 3;
            app.mag = [50 , zeros(1,app.NumberofHarmoniccontent.Value-1)];
            app.phase = zeros(1,app.NumberofHarmoniccontent.Value);
            app.update_plot = 0;
            
            createobj(app);
        end

        % Value changed function: waves
        function wavesValueChanged(app, event)
            update(app);

        end

        % Value changed function: NumberofHarmoniccontent
        function NumberofHarmoniccontentValueChanged(app, event)
            createobj(app);
        end

        % Value changed function: LockPlotSwitch
        function LockPlotSwitchValueChanged(app, event)
            if ~app.LockPlotSwitch.Value
                update(app);
            end
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50 50 742 682];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Resultant Wave')
            xlabel(app.UIAxes, 'Time')
            ylabel(app.UIAxes, 'Magnitude')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [21 417 709 238];

            % Create NumberofHarmoniccontent
            app.NumberofHarmoniccontent = uieditfield(app.UIFigure, 'numeric');
            app.NumberofHarmoniccontent.Limits = [0 Inf];
            app.NumberofHarmoniccontent.RoundFractionalValues = 'on';
            app.NumberofHarmoniccontent.ValueChangedFcn = createCallbackFcn(app, @NumberofHarmoniccontentValueChanged, true);
            app.NumberofHarmoniccontent.Position = [147 390 39 22];
            app.NumberofHarmoniccontent.Value = 3;

            % Create NumberofHarmoniccontentsLabel
            app.NumberofHarmoniccontentsLabel = uilabel(app.UIFigure);
            app.NumberofHarmoniccontentsLabel.HorizontalAlignment = 'right';
            app.NumberofHarmoniccontentsLabel.Position = [31 384 106 28];
            app.NumberofHarmoniccontentsLabel.Text = {'Number of '; 'Harmonic contents'};

            % Create TotalHarmonicDistortionLabel
            app.TotalHarmonicDistortionLabel = uilabel(app.UIFigure);
            app.TotalHarmonicDistortionLabel.BackgroundColor = [1 1 1];
            app.TotalHarmonicDistortionLabel.HorizontalAlignment = 'right';
            app.TotalHarmonicDistortionLabel.Position = [546 387 102 28];
            app.TotalHarmonicDistortionLabel.Text = {'% Total Harmonic '; 'Distortion'};

            % Create ControlPanel
            app.ControlPanel = uipanel(app.UIFigure);
            app.ControlPanel.Title = 'Control Panel';
            app.ControlPanel.Scrollable = 'on';
            app.ControlPanel.Position = [21 41 695 331];

            % Create TotalHarmonicDistortionEditField
            app.TotalHarmonicDistortionEditField = uieditfield(app.UIFigure, 'numeric');
            app.TotalHarmonicDistortionEditField.Editable = 'off';
            app.TotalHarmonicDistortionEditField.BackgroundColor = [0.0745 0.6235 1];
            app.TotalHarmonicDistortionEditField.Position = [656 393 60 22];

            % Create THDandIHDSignificanceVisualiserbySnehKothariLabel
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel = uilabel(app.UIFigure);
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel.HorizontalAlignment = 'center';
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel.FontName = 'Comic Sans MS';
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel.FontSize = 16;
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel.FontAngle = 'italic';
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel.Position = [177 658 413 25];
            app.THDandIHDSignificanceVisualiserbySnehKothariLabel.Text = 'THD and IHD Significance Visualiser by Sneh Kothari';

            % Create ShowallwavesLabel
            app.ShowallwavesLabel = uilabel(app.UIFigure);
            app.ShowallwavesLabel.HorizontalAlignment = 'right';
            app.ShowallwavesLabel.Position = [206 384 54 28];
            app.ShowallwavesLabel.Text = {'Show all '; 'waves'};

            % Create waves
            app.waves = uiswitch(app.UIFigure, 'slider');
            app.waves.ItemsData = [0 1];
            app.waves.ValueChangedFcn = createCallbackFcn(app, @wavesValueChanged, true);
            app.waves.Position = [288 391 45 20];
            app.waves.Value = 0;

            % Create LockPlotSwitchLabel
            app.LockPlotSwitchLabel = uilabel(app.UIFigure);
            app.LockPlotSwitchLabel.HorizontalAlignment = 'center';
            app.LockPlotSwitchLabel.Position = [384 385 31 28];
            app.LockPlotSwitchLabel.Text = {'Lock'; 'Plot'};

            % Create LockPlotSwitch
            app.LockPlotSwitch = uiswitch(app.UIFigure, 'slider');
            app.LockPlotSwitch.ItemsData = [0 1];
            app.LockPlotSwitch.ValueChangedFcn = createCallbackFcn(app, @LockPlotSwitchValueChanged, true);
            app.LockPlotSwitch.Position = [451 392 45 20];
            app.LockPlotSwitch.Value = 0;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = thd_ihd_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end