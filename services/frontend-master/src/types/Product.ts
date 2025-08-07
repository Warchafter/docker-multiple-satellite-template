export interface IProduct {
    id: number;
    name: string;
    price: string;
    description: string;
    images: Array<{
        src: string;
        alt: string;
    }>;
}