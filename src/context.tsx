import {createContext,useContext} from 'react';
import type {Profile,Post,Thread} from './types';
export type Route={name:'home'|'explore'|'chats'|'profile'|'create'|'edit'|'settings'|'people'|'conversation';person?:Profile;thread?:Thread};
export type Context={me:Profile;setMe:(p:Profile)=>void;posts:Post[];followed:string[];push:(r:Route)=>void;back:()=>void;run:(fn:()=>Promise<unknown>)=>Promise<void>;notify:(s:string)=>void;refresh:()=>Promise<void>;view:(posts:Post[],index:number)=>void;comments:(p:Post)=>void;lightbox:(url:string,kind?:string)=>void;theme:string;setTheme:(v:string)=>void;logout:()=>Promise<void>;loadMore:()=>Promise<void>;hasMore:boolean};
export const Ctx=createContext<Context>(null!);export const useApp=()=>useContext(Ctx);
