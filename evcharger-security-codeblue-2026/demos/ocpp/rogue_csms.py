import asyncio, logging
from datetime import datetime, timezone

import websockets
from ocpp.routing import on
from ocpp.v16 import ChargePoint, call, call_result
from ocpp.v16.enums import Action, RegistrationStatus

logging.basicConfig(level=logging.INFO, format="[csms] %(message)s")
FIRMWARE_URL = "http://firmware.example.invalid/fw.bin"


def now():
    return datetime.now(timezone.utc).isoformat()


class CSMS(ChargePoint):
    @on(Action.boot_notification)
    def on_boot(self, **_):
        return call_result.BootNotification(current_time=now(), interval=300, status=RegistrationStatus.accepted)


async def push_firmware(cp):
    await asyncio.sleep(1)
    await cp.call(call.UpdateFirmware(location=FIRMWARE_URL, retrieve_date=now()))


async def on_connect(ws):
    cp = CSMS(ws.request.path.strip("/"), ws)
    asyncio.create_task(push_firmware(cp))
    try:
        await cp.start()
    except websockets.ConnectionClosed:
        pass


async def main():
    async with websockets.serve(on_connect, "127.0.0.1", 9000, subprotocols=["ocpp1.6"]):
        await asyncio.Future()


asyncio.run(main())
