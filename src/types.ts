export type Media = {type:'image'|'video'|'embed';url:string;poster?:string};
export type Profile = {id:string;username:string;name:string;bio:string;avatar:string;website?:string};
export type Post = {id:string;user_id:string;caption:string;media:Media[];created_at:string;owner:Profile;likes:{user_id:string}[];saves:{user_id:string}[];comments:{id:string}[]};
export type Comment = {id:string;post_id:string;user_id:string;body:string;created_at:string;owner:Profile};
export type Thread = {id:string;user_a:string;user_b:string;created_at:string;peer:Profile;last?:Message;unread:number};
export type Message = {id:string;thread_id:string;sender_id:string;kind:'text'|'image'|'video'|'audio';body:string;media_path:string;created_at:string;read_at:string|null;url?:string};
export type Config = {supabaseUrl:string;supabaseAnonKey:string};
