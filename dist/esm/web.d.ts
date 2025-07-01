import { WebPlugin } from "@capacitor/core";
import type { ScreenRecorderPlugin } from "./definitions";
export declare class ScreenRecorderWeb extends WebPlugin implements ScreenRecorderPlugin {
    start(): Promise<void>;
    stop(): Promise<void>;
}
