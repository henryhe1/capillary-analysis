function varargout = validate_gui(varargin)
% validate_gui MATLAB code for validate_gui.fig
%      validate_gui, by itself, creates a new validate_gui or raises the existing
%      singleton*.
%
%      H = validate_gui returns the handle to a new validate_gui or the handle to
%      the existing singleton*.
%
%      validate_gui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in validate_gui.M with the given input arguments.
%
%      validate_gui('Property','Value',...) creates a new validate_gui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before validate_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to validate_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help validate_gui

% Last Modified by GUIDE v2.5 04-Aug-2017 00:31:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @validate_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @validate_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before validate_gui is made visible.
function validate_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to validate_gui (see VARARGIN)

% Choose default command line output for validate_gui
handles.output = hObject;
handles.rangeFiltSelected = 0;

% Set the default area as all 1s (everything is shown, no mask)
handles.area = ones(520, 696);

% Initialize variables
handles.labelledImageStr = [];
handles.capArea = [];
handles.fnames = {};
handles.frameNumber = 1;
handles.rangeFiltSelected = 0;
handles.textSelected = 0;
handles.boxSelected = 0;

% Validate mode unique!
handles.validateMode = false;
handles.focusMask = [];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes validate_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
% This is actually the last function that runs when you close the gui
% because of uiresume in closingfcn 
function varargout = validate_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.capArea;
delete(hObject); % Clean up

% --- Executes on button press in load_button.
function load_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% Load the frames specified by the user inputted path
[fnames, path] = getFnames;
handles.fnames = fnames;

% Loading bar since it seems to take a while
h = waitbar(0,'Loading..');

% Get the path string and use it to find the labelled image
path = strrep(path, 'Captured', 'Processed');


% Remove wavelength directory string
path = strrep(path, [filesep '442'], '');
path = strrep(path, [filesep '454'], '');


waitbar(0.25,h);

handles.fovName = path(strfind(path, 'X20'):end-1);
handles.labelledImageStr = strrep([path 'VesselGeometry/' handles.fovName 'GradientImageLabelled.fig'], '\', '/');

% Show the first frame in axes1
imshow(imread(fnames{1}), 'Parent', handles.axes1, 'DisplayRange', [0 65536]);

% Calculate and store the variance image of the frames
handles.varianceImage = imread(strrep([path 'Functional-16bitImages/' handles.fovName '-16bit442Var.tif'], '\', '/'));

% Store the max image of the frames
handles.maxImage = imread(strrep([path 'Functional-16bitImages/' handles.fovName '-16bit442Max.tif'], '\', '/'));

% Store the capillary area mask
[handles.capArea, handles.idList] = getCapillaries(handles.varianceImage);

handles.focusMask = handles.capArea;

% Store location of capillary text labels
handles.coords = getLabelLocation(handles.capArea, handles.idList);
handles.textHandles = zeros(size(handles.idList, 1));

waitbar(0.50,h);

% Calculate data for labelled image

if exist(handles.labelledImageStr, 'file')
    openfig(handles.labelledImageStr, 'new', 'invisible');
    myhandle = findall(gcf, 'type', 'image');
    labelledImage = get(myhandle, 'cdata');
    imshow(labelledImage, 'Parent', handles.axes2, 'DisplayRange', []);
    myhandle = findall(gcf, 'type', 'text');
    handles.position = get(myhandle, 'position');
    handles.textStr = get(myhandle, 'string');
    delete(gcf);
    axes(handles.axes2);
    
    for i = 1:size(handles.position, 1)
    cellData = handles.position{i};
        if cellData(2) >= 0 && cellData(1) >= 0 && ~strcmp(handles.textStr{i}, 'pixels')
            text(cellData(1), cellData(2), handles.textStr{i}, 'Color', 'white');
        end
    end
end

waitbar(0.75,h);
set(handles.text1, 'String', [handles.fovName ' loaded']);

freezeColors
guidata(hObject, handles);
close(h);


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.frameNumber = uint8(str2double(get(hObject, 'String')));
guidata(hObject, handles);


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

% Get the current frame number from the editable text
handles.frameNumber = uint8(str2double(get(hObject, 'String')));

% Set the location of the slider
set(handles.slider1, 'Value', str2double(get(hObject, 'String')));

% Show the current frame / area
refresh(handles);
guidata(hObject, handles);



% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% If the frame has not been loaded yet, do nothing
if isempty(handles.fnames)
    return;
end

% Get the current frame number from the slider location
handles.frameNumber = uint16(get(hObject, 'Value'));

% Set the editable text value
set(handles.edit1, 'String', handles.frameNumber);

refresh(handles);

guidata(hObject, handles);


% --- Executes when selected object is changed in uipanel4.
function uipanel4_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel4 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% If the frame has not been loaded yet, do nothing
if isempty(handles.fnames)
    return;
    
elseif strcmp(get(hObject, 'Tag'), 'capillary_button')
    handles.area = handles.capArea;
    handles.rangeFiltSelected = 0;
    refresh(handles);
    
elseif strcmp(get(hObject, 'Tag'), 'range_button')
    handles.area = handles.capArea;
    handles.rangeFiltSelected = 1;
    refresh(handles);
    
else
    handles.area = ones(520, 696);
    handles.rangeFiltSelected = 0;
    refresh(handles);
end

guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes on key press with focus on slider1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% If the frame has not been loaded yet, do nothing
if isempty(handles.fnames)
    return;
end

switch eventdata.Key
    case 'rightarrow'
        if str2double(get(handles.edit1, 'String')) + 1 <= 1260
            set(handles.slider1, 'Value', str2double(get(handles.edit1, 'String')) + 1);
            set(handles.edit1, 'String', str2double(get(handles.edit1, 'String')) + 1);
            handles.frameNumber = handles.frameNumber + 1;
            refresh(handles);
        end
        
    case 'leftarrow'
        if str2double(get(handles.edit1, 'String')) - 1 > 0
            set(handles.slider1, 'Value', str2double(get(handles.edit1, 'String')) - 1);
            set(handles.edit1, 'String', str2double(get(handles.edit1, 'String')) - 1);
            handles.frameNumber = handles.frameNumber - 1;
            refresh(handles);
        end
    
    otherwise
        
end


guidata(hObject, handles);



% --- Executes when selected object is changed in uipanel5.
function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% If the frame has not been loaded yet, do nothing
if isempty(handles.fnames)
    return;
end

if strcmp(get(hObject, 'Tag'), 'var_button')
    imshow(handles.varianceImage, 'Parent', handles.axes2, 'DisplayRange', []);
elseif strcmp(get(hObject, 'Tag'), 'label_button')
   
    if exist(handles.labelledImageStr, 'file')
        openfig(handles.labelledImageStr, 'new', 'invisible');
        myhandle = findall(gcf, 'type', 'image');
        labelledImage = get(myhandle, 'cdata');
        imshow(labelledImage, 'Parent', handles.axes2, 'DisplayRange', []);
        myhandle = findall(gcf, 'type', 'text');
        handles.position = get(myhandle, 'position');
        handles.textStr = get(myhandle, 'string');
        delete(gcf);
        axes(handles.axes2);

        for i = 1:size(handles.position, 1)
        cellData = handles.position{i};
            if cellData(2) >= 0 && cellData(1) >= 0 && ~strcmp(handles.textStr{i}, 'pixels')
                text(cellData(1), cellData(2), handles.textStr{i}, 'Color', 'white');
            end
        end
    end
else
    showArea = imread(handles.fnames{handles.frameNumber});
    showArea(~handles.capArea) = 0;
    imshow(showArea, 'Parent', handles.axes2, 'DisplayRange', [0 65536]);
end
    


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1

function refresh (handles)
axes(handles.axes1);
showArea = imread(handles.fnames{handles.frameNumber});

    
if handles.rangeFiltSelected
    showArea = rangefilt(showArea);
    showArea(~handles.area) = 0;
    imshow(showArea, 'Parent', handles.axes1, 'DisplayRange', []);
else
    showArea(~handles.area) = 0;
    imshow(showArea, 'Parent', handles.axes1, 'DisplayRange', [0 65536]);
end

if handles.textSelected
    if handles.area == handles.capArea
        color = 'white';
    else
        color = 'black';
    end
    
    for i = 1:size(handles.idList, 1)
        text(handles.coords(i, 2), handles.coords(i, 1), num2str(handles.idList(i, 1)), 'Color', color);
    end
end





% --- Executes on button press in labelbutton.
function labelbutton_Callback(hObject, eventdata, handles)
% hObject    handle to labelbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of labelbutton
if get(hObject, 'Value')
    handles.textSelected = 1;
else
    handles.textSelected = 0;
end

refresh(handles);
guidata(hObject, handles);

% --- Executes on key press with focus on edit1 and none of its controls.
function edit1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% Used in validate_gui to find a location to place the ID label of a capillary
% Puts it at the highest y-coordinate

function coords = getLabelLocation(area, idList)

coords = zeros(size(idList));

for i = 1:size(idList, 1)
% Get smallest Y-value
indices = find(area == idList(i, 1));

subs = zeros(numel(indices), 2);
[subs(:, 1), subs(:, 2)] = ind2sub(size(area), indices);
subs = sortrows(subs, 1);
coords(i, :) = subs(1, :);
end


% --- Executes during object creation, after setting all properties.
function text1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on key press with focus on edit1 and none of its controls.
function slider1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
uiresume(handles.figure1)



% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


handles.validateMode = ~handles.validateMode;

if handles.validateMode
    set(handles.pushbutton5, 'String', 'Exit Focus Assign');
else
    set(handles.pushbutton5, 'String', 'Enter Focus Assign');
end



guidata(hObject, handles);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton5.
function pushbutton5_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.validateMode
    
    get(hObject,'CurrentPoint')
end
