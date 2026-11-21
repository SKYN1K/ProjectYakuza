import argparse
import ctypes
import importlib.util
import json
import os
import re
import sys
import time
from pathlib import Path


class Message(ctypes.Structure):
    _fields_ = [('user', ctypes.c_int), ('callback', ctypes.c_int), ('data', ctypes.c_void_p), ('size', ctypes.c_int)]


class Completed(ctypes.Structure):
    _fields_ = [('call', ctypes.c_uint64), ('callback', ctypes.c_int), ('size', ctypes.c_uint32)]


class SubmitResult(ctypes.Structure):
    _fields_ = [('result', ctypes.c_int), ('legal', ctypes.c_bool), ('item', ctypes.c_uint64)]


ROOT = Path(__file__).resolve().parents[1]


def prepare(folder, item_id=None):
    folder = Path(folder).resolve()
    contents = folder / 'Contents'
    mods = contents / 'mods'
    if not mods.is_dir():
        raise ValueError('Select the Workshop item folder containing Contents/mods, not the source mod or a ZIP.')
    metadata = folder / 'workshop.txt'
    match = re.search(r'^id=(\d+)\s*$', metadata.read_text(encoding='utf-8-sig'), re.M) if metadata.is_file() else None
    stored_id = int(match[1]) if match else None
    item_id = item_id or stored_id
    if not item_id or item_id <= 0:
        raise ValueError('An existing Workshop item ID is required; this tool never creates an item.')
    if stored_id and item_id != stored_id:
        raise ValueError('The supplied item ID differs from workshop.txt; no upload was started.')
    spec = importlib.util.spec_from_file_location('game_package', ROOT / 'tools/Build-GamePackage.py')
    package = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(package)
    allowed = set()
    total = 0
    mod_ids = []
    for mod in sorted(mods.iterdir()):
        if not mod.is_dir() or not mod.resolve().is_relative_to(contents):
            raise ValueError('Unexpected file or external directory inside Contents/mods: ' + mod.name)
        files = package.runtime_files(mod)
        info = (mod / '42/mod.info').read_text(encoding='utf-8-sig')
        identifier = re.search(r'^id=(.+)$', info, re.M)
        if not identifier or not identifier[1].strip():
            raise ValueError('Missing mod ID: ' + mod.name)
        mod_ids.append(identifier[1].strip())
        for name, source in files.items():
            allowed.add('mods/' + mod.name + '/' + name)
            total += source.stat().st_size
    actual = {p.relative_to(contents).as_posix() for p in contents.rglob('*') if p.is_file()}
    if not allowed or actual != allowed:
        raise ValueError('Contents contains missing or non-runtime files: ' + ', '.join(sorted(actual ^ allowed)))
    return item_id, contents, len(allowed), total, mod_ids


def begin_update(start, set_content, submit, ugc, item_id, contents, note):
    handle = start(ugc, 108600, item_id)
    if not handle or handle == 18446744073709551615:
        raise RuntimeError('Steam could not start an update for this item.')
    if not set_content(ugc, handle, str(contents).encode('utf-8')):
        raise RuntimeError('Steam rejected the content folder.')
    call = submit(ugc, handle, note.encode('utf-8') if note else None)
    if not call:
        raise RuntimeError('Steam did not accept the upload request.')
    return handle, call


def upload(game_folder, item_id, contents, note):
    game = Path(game_folder).resolve()
    if sys.platform != 'win32' or ctypes.sizeof(ctypes.c_void_p) != 8:
        raise RuntimeError('This uploader requires 64-bit Python on Windows.')
    if not (game / 'steam_api64.dll').is_file():
        raise ValueError('GameFolder must contain the installed PZ steam_api64.dll.')
    os.environ['SteamAppId'] = '108600'
    os.environ['SteamGameId'] = '108600'
    with os.add_dll_directory(str(game)):
        api = ctypes.CDLL(str(game / 'steam_api64.dll'))
        def function(name, result, arguments):
            fn = getattr(api, name)
            fn.restype = result
            fn.argtypes = arguments
            return fn
        pointer = ctypes.c_void_p
        u64 = ctypes.c_uint64
        error = ctypes.create_string_buffer(1024)
        if function('SteamAPI_InitFlat', ctypes.c_int, [ctypes.c_char_p])(error) != 0:
            raise RuntimeError('Keep Steam running and signed in as the Workshop item owner. ' + error.value.decode(errors='replace'))
        try:
            api.SteamAPI_ManualDispatch_Init()
            pipe = function('SteamAPI_GetHSteamPipe', ctypes.c_int, [])()
            run = function('SteamAPI_ManualDispatch_RunFrame', None, [ctypes.c_int])
            next_message = function('SteamAPI_ManualDispatch_GetNextCallback', ctypes.c_bool, [ctypes.c_int, ctypes.POINTER(Message)])
            free_message = function('SteamAPI_ManualDispatch_FreeLastCallback', None, [ctypes.c_int])
            get_result = function('SteamAPI_ManualDispatch_GetAPICallResult', ctypes.c_bool, [ctypes.c_int, u64, pointer, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_bool)])
            ugc = function('SteamAPI_SteamUGC_v021', pointer, [])()
            start = function('SteamAPI_ISteamUGC_StartItemUpdate', u64, [pointer, ctypes.c_uint32, u64])
            set_content = function('SteamAPI_ISteamUGC_SetItemContent', ctypes.c_bool, [pointer, u64, ctypes.c_char_p])
            submit = function('SteamAPI_ISteamUGC_SubmitItemUpdate', u64, [pointer, u64, ctypes.c_char_p])
            progress = function('SteamAPI_ISteamUGC_GetItemUpdateProgress', ctypes.c_int, [pointer, u64, ctypes.POINTER(u64), ctypes.POINTER(u64)])
            handle, call = begin_update(start, set_content, submit, ugc, item_id, contents, note)
            deadline = time.monotonic() + 600
            last = None
            while time.monotonic() < deadline:
                run(pipe)
                message = Message()
                while next_message(pipe, ctypes.byref(message)):
                    try:
                        if message.callback != 703 or message.size < ctypes.sizeof(Completed):
                            continue
                        completed = ctypes.cast(message.data, ctypes.POINTER(Completed)).contents
                        if completed.call != call:
                            continue
                        if completed.callback != 3404 or completed.size != ctypes.sizeof(SubmitResult):
                            raise RuntimeError('Unexpected Steam upload callback; check the Workshop page before retrying.')
                        result, failed = SubmitResult(), ctypes.c_bool()
                        received = get_result(pipe, call, ctypes.byref(result), ctypes.sizeof(result), 3404, ctypes.byref(failed))
                        if not received or failed.value or result.result != 1 or result.item != item_id:
                            raise RuntimeError('Steam upload failed with result ' + str(result.result) + '.')
                        if result.legal:
                            raise RuntimeError('Steam requires you to accept the Workshop agreement on the item page.')
                        print('Content uploaded successfully. No page-metadata fields were submitted.', flush=True)
                        return
                    finally:
                        free_message(pipe)
                processed, total = u64(), u64()
                state = progress(ugc, handle, ctypes.byref(processed), ctypes.byref(total))
                current = (state, processed.value // 10485760)
                if current != last:
                    names = {0: 'Waiting', 1: 'Preparing', 2: 'Checking files', 3: 'Uploading', 4: 'Uploading', 5: 'Committing'}
                    print(f'{names.get(state, "Working")}: {processed.value:,} / {total.value:,} bytes', flush=True)
                    last = current
                time.sleep(.25)
            raise RuntimeError('No final result after ten minutes. The update may still complete; check the Workshop page before retrying.')
        finally:
            api.SteamAPI_Shutdown()


def main(argv=None):
    parser = argparse.ArgumentParser(description='Update PZ Workshop content without submitting page metadata.')
    parser.add_argument('--workshop-folder', type=Path)
    parser.add_argument('--game-folder', type=Path)
    parser.add_argument('--item-id', type=int)
    parser.add_argument('--change-note')
    parser.add_argument('--upload', action='store_true')
    args = parser.parse_args(argv)
    settings_path = ROOT / 'tools/WorkshopUpload.local.json'
    settings = json.loads(settings_path.read_text(encoding='utf-8-sig')) if settings_path.is_file() else {}
    if not args.workshop_folder and settings.get('WorkshopFolder'):
        args.workshop_folder = Path(settings['WorkshopFolder'])
    if not args.game_folder and settings.get('GameFolder'):
        args.game_folder = Path(settings['GameFolder'])
    if not args.workshop_folder:
        raise ValueError('Provide --workshop-folder for the item folder containing Contents and workshop.txt.')
    item_id, contents, count, size, mod_ids = prepare(args.workshop_folder, args.item_id)
    print(f'Workshop item: {item_id}\nMods: {", ".join(mod_ids)}\nRuntime files: {count:,}\nContent size: {size:,} bytes', flush=True)
    if not args.upload:
        print('Validation only; nothing was uploaded. Add --upload to send the content.')
        return
    if not args.game_folder:
        raise ValueError('--game-folder is required for uploading.')
    upload(args.game_folder, item_id, contents, args.change_note)


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        sys.exit(1)
