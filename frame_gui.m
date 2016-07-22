function varargout = frame_gui(varargin)
% FRAME_GUI MATLAB code for frame_gui.fig
%      FRAME_GUI, by itself, creates a new FRAME_GUI or raises the existing
%      singleton*.
%
%      H = FRAME_GUI returns the handle to a new FRAME_GUI or the handle to
%      the existing singleton*.
%
%      FRAME_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FRAME_GUI.M with the given input arguments.
%
%      FRAME_GUI('Property','Value',...) creates a new FRAME_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before frame_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to frame_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help frame_gui

% Last Modified by GUIDE v2.5 16-Jun-2016 15:50:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @frame_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @frame_gui_OutputFcn, ...
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


% --- Executes just before frame_gui is made visible.
function frame_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to frame_gui (see VARARGIN)

% Choose default command line output for frame_gui
handles.output = hObject;
handles.rangeFiltSelected = 0;

% Set the default area as all 1s (everything is shown, no mask)
handles.area = ones(520, 696);

% Initialize variables
handles.capArea = [];
handles.fnames = {};
handles.labelledImage = [];
handles.frameNumber = 1;
handles.rangeFiltSelected = 0;
handles.textSelected = 0;


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes frame_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = frame_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in load_button.
function load_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load the frames specified by the user inputted path
[fnames, path] = getFnames;
handles.fnames = fnames;

% Get the path string and use it to find the labelled image
path = strrep(path, 'Captured', 'Processed');

path = strrep(path, '/442', '');
path = strrep(path, '/454', '');


fovName = path(strfind(path, 'X20'):end-1);
%handles.labelledImage = [path 'JPEGImages/' fovName 'FunctionalImageLabelled.jpg'];
handles.labelledImage = [path 'VesselGeometry/' fovName 'GradientImageLabelled.fig'];

% Show the first frame in axes1
imshow(imread(fnames{1}), 'Parent', handles.axes1, 'DisplayRange', [0 65536]);

% Calculate and store the variance image of the frames
handles.varianceImage = getVarianceImage(fnames);

% Store the capillary area mask
[handles.capArea, handles.idList] = getCapillaries(handles.varianceImage);

% Store location of capillary text labels
handles.coords = getLabelLocation(handles.capArea, handles.idList);
handles.textHandles = zeros(size(handles.idList, 1));

% Calculate data for labelled image
openfig(handles.labelledImage, 'new', 'invisible');
myhandle = findall(gcf, 'type', 'image');
handles.labelledImage = get(myhandle, 'cdata');
imshow(handles.labelledImage, 'Parent', handles.axes2, 'DisplayRange', []);
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

guidata(hObject, handles);


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
end

if strcmp(get(hObject, 'Tag'), 'capillary_button')
    handles.area = handles.capArea;
else
    handles.area = ones(520, 696);
end

handles.rangeFiltSelected = 0;
if strcmp(get(hObject, 'Tag'), 'range_button')
    handles.area = handles.capArea;
    handles.rangeFiltSelected = 1;
end

refresh(handles);


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
else
    
    imshow(handles.labelledImage, 'Parent', handles.axes2, 'DisplayRange', []);
    axes(handles.axes2);
    for i = 1:size(handles.position, 1)
        cellData = handles.position{i};
        if cellData(2) >= 0 && cellData(1) >= 0 && ~strcmp(handles.textStr{i}, 'pixels')
            text(cellData(1), cellData(2), handles.textStr{i}, 'Color', 'white');
        end

    end
    
    
    
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

% Used in frame_gui to find a location to place the ID label of a capillary
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

