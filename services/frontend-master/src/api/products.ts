import type { IProduct } from "../types/Product";

const WP_API_BASE = import.meta.env.PUBLIC_WP_API;

export async function fetchProduct(id: number): Promise<IProduct> {
    console.log("WP_API_BASE", WP_API_BASE);
    const res = await fetch(`${WP_API_BASE}/products/${id}`);
    console.log(res);
    if (!res.ok) {
        throw new Error(`Failed to fetch product ${id}: ${res.statusText}`);
    }
    const data = await res.json();
    return data as IProduct;
}