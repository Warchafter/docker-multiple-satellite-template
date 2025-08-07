import { useEffect, useState } from "react";
import type { IProduct } from "../types/Product";
import { fetchProduct } from "../api/products";

interface ProductCardProps {
    productId: number;
}

export const ProductCard = ({ productId }: ProductCardProps) => {
    const [product, setProduct] = useState<IProduct | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        let cancelled = false;

        fetchProduct(productId)
            .then((product) => {
                console.log("productId: ", productId);
                if (!cancelled) setProduct(product);
            })
            .catch((err) => {
                if (!cancelled) setError(err.message);
            });

        return () => {
            cancelled = true;
        };
    }, [productId]);

    if (error) {
        return <div className="text-red-600">Error: {error}</div>
    }

    if (!product) {
        return <div>Loading...</div>;
    }

    return (
        <div className="max-w-sm border rounded shadow p-4">
            <h3 className="text-2xl font-bold">{product.name}</h3>
            <p className="text-gray-700" dangerouslySetInnerHTML={{ __html: product.description }} />
            {product.images[0] && (
                <img
                    src={product.images[0].src}
                    alt={product.images[0].alt}
                    className="w-full h-auto mt-4"
                />
            )}
            <div className="mt-2 text-xl font-semibold">${product.price}</div>
        </div>
    )    
}