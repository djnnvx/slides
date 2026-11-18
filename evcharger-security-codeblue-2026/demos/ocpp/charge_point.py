import asyncio, logging

import websockets
from ocpp.routing import on
from ocpp.v16 import ChargePoint, call, call_result
from ocpp.v16.enums import Action

logging.basicConfig(level=logging.INFO, format="[cp]   %(message)s")


class SimCharger(ChargePoint):
    @on(Action.update_firmware)
    def on_update_firmware(self, location, **_):
        logging.info(f"firmware update accepted, would fetch {location}")
        return call_result.UpdateFirmware()


async def main():
    async with websockets.connect("ws://127.0.0.1:9000/CP_0142", subprotocols=["ocpp1.6"]) as ws:
        cp = SimCharger("CP_0142", ws)
        boot = cp.call(call.BootNotification(charge_point_model="SimCharger", charge_point_vendor="Demo"))
        _, pending = await asyncio.wait({asyncio.create_task(cp.start()), asyncio.create_task(boot)}, timeout=3)
        for t in pending:
            t.cancel()


asyncio.run(main())
